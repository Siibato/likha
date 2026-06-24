use crate::utils::error::{AppError, AppResult};
use uuid::Uuid;

impl crate::modules::learning_material::service::LearningMaterialService {
    pub async fn soft_delete(&self, material_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
        let material = self
            .material_repo
            .find_by_id(material_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?;

        let _class = self
            .class_repo
            .find_by_id(material.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self
            .class_repo
            .is_teacher_of_class(teacher_id, material.class_id)
            .await?
        {
            return Err(AppError::Forbidden(
                "You can only delete materials from your own classes".to_string(),
            ));
        }

        self.material_repo.soft_delete(material_id).await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_material_detail(material_id).await;
            inv.invalidate_material_list(material.class_id).await;
        }

        Ok(())
    }
}
