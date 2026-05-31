use uuid::Uuid;
use crate::utils::error::AppResult;
use crate::schema::learning_material_schema::{CreateMaterialRequest, MaterialResponse};

impl crate::services::learning_material::LearningMaterialService {
    pub async fn create_material(
        &self,
        class_id: Uuid,
        request: CreateMaterialRequest,
        teacher_id: Uuid,
        client_id: Option<Uuid>,
    ) -> AppResult<MaterialResponse> {
        self.verify_teacher_owns_class(class_id, teacher_id).await?;

        let title = Self::validate_title(&request.title)?;
        let description = Self::validate_description(&request.description)?;
        let content_text = Self::validate_content_text(&request.content_text)?;

        let max_order = self.material_repo.get_max_order_index(class_id).await?;
        let order_index = max_order + 1;

        let material = self
            .material_repo
            .create_material(class_id, title, description, content_text, order_index, client_id)
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "material_created",
                Some(format!("Learning material '{}' created", material.title)),
            )
            .await;

        Ok(MaterialResponse {
            id: material.id,
            class_id: material.class_id,
            title: material.title,
            description: material.description,
            content_text: material.content_text,
            order_index: material.order_index,
            file_count: 0,
            created_at: material.created_at.to_string(),
            updated_at: material.updated_at.to_string(),
        })
    }
}
