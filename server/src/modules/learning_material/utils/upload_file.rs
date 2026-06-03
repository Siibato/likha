use std::path::PathBuf;
use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::learning_material::schema::FileMetadataResponse;
use crate::modules::learning_material::service::{MAX_FILE_SIZE_MB, MAX_FILES_PER_MATERIAL};
use crate::utils::file_service;

impl crate::modules::learning_material::service::LearningMaterialService {
    pub async fn upload_file(
        &self,
        material_id: Uuid,
        file_name: String,
        file_type: String,
        file_data: Vec<u8>,
        teacher_id: Uuid,
    ) -> AppResult<FileMetadataResponse> {
        let material = self
            .material_repo
            .find_by_id(material_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?;

        self.verify_teacher_owns_class(material.class_id, teacher_id)
            .await?;

        let file_size = file_data.len() as i64;
        let file_size_mb = file_size / (1024 * 1024);

        if file_size_mb > MAX_FILE_SIZE_MB {
            return Err(AppError::BadRequest(format!(
                "File size exceeds maximum of {} MB",
                MAX_FILE_SIZE_MB
            )));
        }

        let current_file_count = self
            .material_repo
            .count_files_by_material(material_id)
            .await?;

        if current_file_count >= MAX_FILES_PER_MATERIAL {
            return Err(AppError::BadRequest(format!(
                "Maximum of {} files per material exceeded",
                MAX_FILES_PER_MATERIAL
            )));
        }

        let file_hash = file_service::compute_hash(&file_data);

        if let Ok(Some(existing_path)) = self.material_repo.find_active_file_path_by_hash(&file_hash).await {
            let file = self
                .material_repo
                .save_file(material_id, file_name.clone(), file_type.clone(), file_size, existing_path, file_hash)
                .await?;

            let _ = self
                .activity_log_repo
                .create_log(
                    teacher_id,
                    "material_file_uploaded",
                    Some(format!(
                        "File '{}' uploaded to material '{}' (deduplicated)",
                        file.file_name, material.title
                    )),
                )
                .await;

            return Ok(FileMetadataResponse {
                id: file.id,
                file_name: file.file_name,
                file_type: file.file_type,
                file_size: file.file_size,
                uploaded_at: file.uploaded_at.to_string(),
            });
        }

        let file_id = Uuid::new_v4();
        let disk_filename = file_service::generate_disk_filename(&file_name, file_id);
        let mut disk_path = PathBuf::from(self.file_storage_path.clone());
        disk_path.push("material_files");
        disk_path.push(&disk_filename);

        if let Err(e) = file_service::write_file(&disk_path, &file_data, Some(&self.file_encryption_key)).await {
            return Err(AppError::InternalServerError(format!("Failed to write file to disk: {}", e)));
        }

        let file_path = disk_path.to_string_lossy().to_string();

        match self
            .material_repo
            .save_file(material_id, file_name.clone(), file_type.clone(), file_size, file_path, file_hash)
            .await
        {
            Ok(file) => {
                let _ = self
                    .activity_log_repo
                    .create_log(
                        teacher_id,
                        "material_file_uploaded",
                        Some(format!(
                            "File '{}' uploaded to material '{}'",
                            file.file_name, material.title
                        )),
                    )
                    .await;

                Ok(FileMetadataResponse {
                    id: file.id,
                    file_name: file.file_name,
                    file_type: file.file_type,
                    file_size: file.file_size,
                    uploaded_at: file.uploaded_at.to_string(),
                })
            }
            Err(e) => {
                file_service::delete_file(&disk_path).await;
                Err(e)
            }
        }
    }
}
