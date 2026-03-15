use std::path::PathBuf;
use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::learning_material_schema::FileMetadataResponse;
use super::learning_material_service::{MAX_FILE_SIZE_MB, MAX_FILES_PER_MATERIAL};
use crate::services::file_service;

impl super::LearningMaterialService {
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

        // Compute file hash for deduplication
        let file_hash = file_service::compute_hash(&file_data);

        // Check if this file already exists
        if let Ok(Some(existing_path)) = self.material_repo.find_active_file_path_by_hash(&file_hash).await {
            // File already exists, reuse it
            let file_id = Uuid::new_v4();
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

        // Generate filename and disk path
        let file_id = Uuid::new_v4();
        let disk_filename = file_service::generate_disk_filename(&file_name, file_id);
        let mut disk_path = PathBuf::from(self.file_storage_path.clone());
        disk_path.push("material_files");
        disk_path.push(&disk_filename);

        // Write file to disk
        if let Err(e) = file_service::write_file(&disk_path, &file_data).await {
            return Err(AppError::InternalServerError(format!("Failed to write file to disk: {}", e)));
        }

        let file_path = disk_path.to_string_lossy().to_string();

        // Save to database
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
                // DB insert failed, delete the file we just wrote
                file_service::delete_file(&disk_path).await;
                Err(e)
            }
        }
    }

    pub async fn delete_file(&self, file_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
        let file = self
            .material_repo
            .find_file_by_id(file_id)
            .await?
            .ok_or_else(|| AppError::NotFound("File not found".to_string()))?;

        let material = self
            .material_repo
            .find_by_id(file.material_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?;

        self.verify_teacher_owns_class(material.class_id, teacher_id)
            .await?;

        // Soft delete the DB row
        self.material_repo.soft_delete_file(file_id).await?;

        // Check if any other rows reference the same hash
        if let (Some(hash), Some(path)) = (file.file_hash, file.file_path) {
            if let Ok(count) = self.material_repo.count_active_by_hash(&hash, file_id).await {
                if count == 0 {
                    // No other references, delete physical file
                    file_service::delete_file(&PathBuf::from(&path)).await;
                }
            }
        }

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "material_file_deleted",
                Some(format!("File '{}' deleted", file.file_name)),
            )
            .await;

        Ok(())
    }

    pub async fn download_file(
        &self,
        file_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<(String, String, Vec<u8>)> {
        let file = self
            .material_repo
            .find_file_by_id(file_id)
            .await?
            .ok_or_else(|| AppError::NotFound("File not found".to_string()))?;

        let material = self
            .material_repo
            .find_by_id(file.material_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?;

        if role == "teacher" {
            self.verify_teacher_owns_class(material.class_id, user_id)
                .await?;
        } else {
            self.verify_student_enrolled(material.class_id, user_id)
                .await?;
        }

        let file_path = file
            .file_path
            .ok_or_else(|| AppError::NotFound("File data not available".to_string()))?;

        let file_bytes = file_service::read_file(&PathBuf::from(&file_path))
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to read file from disk: {}", e)))?;

        Ok((file.file_name, file.file_type, file_bytes))
    }
}