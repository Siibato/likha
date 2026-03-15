use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::learning_material_schema::{
    CreateMaterialRequest, UpdateMaterialRequest, MaterialResponse, MaterialListResponse, MaterialDetailResponse, FileMetadataResponse, ReorderMaterialRequest, ReorderMaterialsRequest,
};

impl super::LearningMaterialService {
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

        // Material deleted

        Ok(())
    }

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

    pub async fn soft_delete(&self, material_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
        let material = self
            .material_repo
            .find_by_id(material_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?;

        let class = self
            .class_repo
            .find_by_id(material.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, material.class_id).await? {
            return Err(AppError::Forbidden(
                "You can only delete materials from your own classes".to_string(),
            ));
        }

        self.material_repo.soft_delete(material_id).await?;

        Ok(())
    }

    pub async fn reorder_materials(
        &self,
        class_id: Uuid,
        request: ReorderMaterialsRequest,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        self.verify_teacher_owns_class(class_id, teacher_id).await?;
        if request.material_ids.is_empty() {
            return Ok(());
        }
        self.material_repo.reorder_materials(class_id, request.material_ids).await?;
        Ok(())
    }
}