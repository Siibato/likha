use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::learning_material::schema::{ReorderMaterialRequest, MaterialResponse};

impl crate::modules::learning_material::service::LearningMaterialService {
    pub async fn reorder_material(
        &self,
        material_id: Uuid,
        request: ReorderMaterialRequest,
        teacher_id: Uuid,
    ) -> AppResult<MaterialResponse> {
        let material = self
            .material_repo
            .find_by_id(material_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?;

        self.verify_teacher_owns_class(material.class_id, teacher_id)
            .await?;

        if request.new_order_index < 0 {
            return Err(AppError::BadRequest(
                "Order index must be non-negative".to_string(),
            ));
        }

        let updated = self
            .material_repo
            .update_order_index(material_id, request.new_order_index)
            .await?;

        let file_count = self
            .material_repo
            .count_files_by_material(material_id)
            .await?;

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
