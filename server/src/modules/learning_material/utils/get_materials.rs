use uuid::Uuid;
use crate::utils::error::AppResult;
use crate::modules::learning_material::schema::{MaterialResponse, MaterialListResponse};

impl crate::modules::learning_material::service::LearningMaterialService {
    pub async fn get_materials(
        &self,
        class_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<MaterialListResponse> {
        if role == "teacher" {
            self.verify_teacher_owns_class(class_id, user_id).await?;
        } else {
            self.verify_student_enrolled(class_id, user_id).await?;
        }

        let materials = self.material_repo.find_by_class_id(class_id).await?;

        if materials.is_empty() {
            return Ok(MaterialListResponse { materials: vec![] });
        }

        let material_ids: Vec<Uuid> = materials.iter().map(|m| m.id).collect();
        let file_counts = self.material_repo.count_files_by_materials(&material_ids).await?;

        let material_responses = materials.into_iter().map(|material| {
            let file_count = file_counts.get(&material.id).copied().unwrap_or(0);
            MaterialResponse {
                id: material.id,
                class_id: material.class_id,
                title: material.title,
                description: material.description,
                content_text: material.content_text,
                order_index: material.order_index,
                file_count,
                created_at: material.created_at.to_string(),
                updated_at: material.updated_at.to_string(),
            }
        }).collect();

        Ok(MaterialListResponse {
            materials: material_responses,
        })
    }
}
