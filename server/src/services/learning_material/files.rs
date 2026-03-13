use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::learning_material_schema::FileMetadataResponse;
use super::learning_material_service::{MAX_FILE_SIZE_MB, MAX_FILES_PER_MATERIAL};

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

        let file = self
            .material_repo
            .save_file(material_id, file_name, file_type, file_size, file_data)
            .await?;

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

        self.material_repo.delete_file(file_id).await?;

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

        Ok((file.file_name, file.file_type, file.file_data))
    }
}