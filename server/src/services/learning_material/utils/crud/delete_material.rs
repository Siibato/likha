use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};

impl crate::services::learning_material::LearningMaterialService {
    pub async fn delete_material(&self, material_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
        let material = self
            .material_repo
            .find_by_id(material_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?;

        self.verify_teacher_owns_class(material.class_id, teacher_id)
            .await?;

        self.material_repo.soft_delete(material_id).await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "material_deleted",
                Some(format!("Learning material '{}' deleted", material.title)),
            )
            .await;

        Ok(())
    }
}
