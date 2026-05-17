use uuid::Uuid;
use crate::utils::error::AppResult;
use crate::schema::learning_material_schema::{MaterialResponse, MaterialListResponse};

impl crate::services::learning_material::LearningMaterialService {
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

        let mut material_responses = Vec::new();
        for material in materials {
            let file_count = self
                .material_repo
                .count_files_by_material(material.id)
                .await?;

            material_responses.push(MaterialResponse {
                id: material.id,
                class_id: material.class_id,
                title: material.title,
                description: material.description,
                content_text: material.content_text,
                order_index: material.order_index,
                file_count,
                created_at: material.created_at.to_string(),
                updated_at: material.updated_at.to_string(),
            });
        }

        Ok(MaterialListResponse {
            materials: material_responses,
        })
    }
}
