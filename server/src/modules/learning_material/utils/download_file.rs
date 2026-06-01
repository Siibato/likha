use std::path::PathBuf;
use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::services::file_service;

impl crate::modules::learning_material::service::LearningMaterialService {
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

        let file_bytes = file_service::read_file(&PathBuf::from(&file_path), Some(&self.file_encryption_key))
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to read file from disk: {}", e)))?;

        Ok((file.file_name, file.file_type, file_bytes))
    }
}
