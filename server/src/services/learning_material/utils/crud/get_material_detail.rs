use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::learning_material_schema::{MaterialDetailResponse, FileMetadataResponse};

impl crate::services::learning_material::LearningMaterialService {
    pub async fn get_material_detail(
        &self,
        material_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<MaterialDetailResponse> {
        let material = self
            .material_repo
            .find_by_id(material_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?;

        if role == "teacher" {
            self.verify_teacher_owns_class(material.class_id, user_id)
                .await?;
        } else {
            self.verify_student_enrolled(material.class_id, user_id)
                .await?;
        }

        let files = self
            .material_repo
            .find_files_by_material(material_id)
            .await?;

        let file_responses: Vec<FileMetadataResponse> = files
            .into_iter()
            .map(|f| FileMetadataResponse {
                id: f.id,
                file_name: f.file_name,
                file_type: f.file_type,
                file_size: f.file_size,
                uploaded_at: f.uploaded_at.to_string(),
            })
            .collect();

        Ok(MaterialDetailResponse {
            id: material.id,
            class_id: material.class_id,
            title: material.title,
            description: material.description,
            content_text: material.content_text,
            order_index: material.order_index,
            files: file_responses,
            created_at: material.created_at.to_string(),
            updated_at: material.updated_at.to_string(),
        })
    }
}
