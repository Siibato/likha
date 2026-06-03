use std::path::PathBuf;
use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::utils::file_service;

impl crate::modules::learning_material::service::LearningMaterialService {
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

        self.material_repo.soft_delete_file(file_id).await?;

        if let (Some(hash), Some(path)) = (file.file_hash, file.file_path) {
            if let Ok(count) = self.material_repo.count_active_by_hash(&hash, file_id).await {
                if count == 0 {
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
}
