use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::learning_material::schema::{UpdateMaterialRequest, MaterialResponse};

impl crate::modules::learning_material::service::LearningMaterialService {
    pub async fn update_material(
        &self,
        material_id: Uuid,
        request: UpdateMaterialRequest,
        teacher_id: Uuid,
    ) -> AppResult<MaterialResponse> {
        let material = self
            .material_repo
            .find_by_id(material_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?;

        self.verify_teacher_owns_class(material.class_id, teacher_id)
            .await?;

        let title = if let Some(t) = &request.title {
            Some(Self::validate_title(t)?)
        } else {
            None
        };

        let description = if let Some(d) = &request.description {
            Some(Self::validate_description(&Some(d.clone()))?)
        } else {
            None
        };

        let content_text = if let Some(c) = &request.content_text {
            Some(Self::validate_content_text(&Some(c.clone()))?)
        } else {
            None
        };

        if let Some(ref inv) = self.invalidator {
            inv.invalidate_material_detail(material_id).await;
            inv.invalidate_material_list(material.class_id).await;
        }

        let updated = self
            .material_repo
            .update_material(material_id, title, description, content_text)
            .await?;

        let file_count = self
            .material_repo
            .count_files_by_material(material_id)
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "material_updated",
                Some(format!("Learning material '{}' updated", updated.title)),
            )
            .await;

        Ok(MaterialResponse {
            id: updated.id,
            class_id: updated.class_id,
            title: updated.title,
            description: updated.description,
            content_text: updated.content_text,
            order_index: updated.order_index,
            file_count,
            created_at: updated.created_at.to_string(),
            updated_at: updated.updated_at.to_string(),
        })
    }
}
