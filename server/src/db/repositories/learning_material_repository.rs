use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::{learning_materials, material_files};
use crate::utils::{AppError, AppResult};

pub struct LearningMaterialRepository {
    db: DatabaseConnection,
}

impl LearningMaterialRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    // ===== LEARNING MATERIALS =====

    pub async fn create_material(
        &self,
        class_id: Uuid,
        title: String,
        description: Option<String>,
        content_text: Option<String>,
        order_index: i32,
        client_id: Option<Uuid>,
    ) -> AppResult<learning_materials::Model> {
        let material = learning_materials::ActiveModel {
            id: Set(client_id.unwrap_or_else(Uuid::new_v4)),
            class_id: Set(class_id),
            title: Set(title),
            description: Set(description),
            content_text: Set(content_text),
            order_index: Set(order_index),
            created_at: Set(Utc::now().naive_utc()),
            updated_at: Set(Utc::now().naive_utc()),
            deleted_at: Set(None),
        };

        material
            .insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create material: {}", e)))
    }

    pub async fn find_by_id(&self, id: Uuid) -> AppResult<Option<learning_materials::Model>> {
        learning_materials::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_by_class_id(&self, class_id: Uuid) -> AppResult<Vec<learning_materials::Model>> {
        learning_materials::Entity::find()
            .filter(learning_materials::Column::ClassId.eq(class_id))
            .filter(learning_materials::Column::DeletedAt.is_null())
            .order_by_asc(learning_materials::Column::OrderIndex)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn update_material(
        &self,
        id: Uuid,
        title: Option<String>,
        description: Option<Option<String>>,
        content_text: Option<Option<String>>,
    ) -> AppResult<learning_materials::Model> {
        let mut material: learning_materials::ActiveModel = learning_materials::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?
            .into();

        if let Some(title) = title {
            material.title = Set(title);
        }
        if let Some(description) = description {
            material.description = Set(description);
        }
        if let Some(content_text) = content_text {
            material.content_text = Set(content_text);
        }

        material.updated_at = Set(Utc::now().naive_utc());

        material
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update material: {}", e)))
    }

    pub async fn delete_material(&self, id: Uuid) -> AppResult<()> {
        learning_materials::Entity::delete_by_id(id)
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to delete material: {}", e)))?;
        Ok(())
    }

    pub async fn update_order_index(&self, id: Uuid, order_index: i32) -> AppResult<learning_materials::Model> {
        let mut material: learning_materials::ActiveModel = learning_materials::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?
            .into();

        material.order_index = Set(order_index);
        material.updated_at = Set(Utc::now().naive_utc());

        material
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update order: {}", e)))
    }

    pub async fn get_max_order_index(&self, class_id: Uuid) -> AppResult<i32> {
        let result = learning_materials::Entity::find()
            .filter(learning_materials::Column::ClassId.eq(class_id))
            .order_by_desc(learning_materials::Column::OrderIndex)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(result.map(|m| m.order_index).unwrap_or(-1))
    }

    // ===== MATERIAL FILES =====

    pub async fn save_file(
        &self,
        material_id: Uuid,
        file_name: String,
        file_type: String,
        file_size: i64,
        file_data: Vec<u8>,
    ) -> AppResult<material_files::Model> {
        let file = material_files::ActiveModel {
            id: Set(Uuid::new_v4()),
            material_id: Set(material_id),
            file_name: Set(file_name),
            file_type: Set(file_type),
            file_size: Set(file_size),
            file_data: Set(file_data),
            uploaded_at: Set(Utc::now().naive_utc()),
        };

        file.insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to save file: {}", e)))
    }

    pub async fn find_file_by_id(&self, id: Uuid) -> AppResult<Option<material_files::Model>> {
        material_files::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_files_by_material(
        &self,
        material_id: Uuid,
    ) -> AppResult<Vec<material_files::Model>> {
        material_files::Entity::find()
            .filter(material_files::Column::MaterialId.eq(material_id))
            .order_by_asc(material_files::Column::UploadedAt)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn delete_file(&self, id: Uuid) -> AppResult<()> {
        material_files::Entity::delete_by_id(id)
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to delete file: {}", e)))?;
        Ok(())
    }

    pub async fn count_files_by_material(&self, material_id: Uuid) -> AppResult<usize> {
        let count = material_files::Entity::find()
            .filter(material_files::Column::MaterialId.eq(material_id))
            .count(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(count as usize)
    }

    pub async fn find_all(&self) -> AppResult<Vec<learning_materials::Model>> {
        learning_materials::Entity::find()
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn soft_delete(&self, id: Uuid) -> AppResult<()> {
        let material = learning_materials::ActiveModel {
            id: Set(id),
            deleted_at: Set(Some(Utc::now().naive_utc())),
            updated_at: Set(Utc::now().naive_utc()),
            ..Default::default()
        };

        learning_materials::Entity::update(material)
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to delete material: {}", e)))?;

        Ok(())
    }

    pub async fn reorder_materials(&self, _class_id: Uuid, material_ids: Vec<Uuid>) -> AppResult<()> {
        for (index, id) in material_ids.iter().enumerate() {
            let material = learning_materials::ActiveModel {
                id: Set(*id),
                order_index: Set(index as i32),
                updated_at: Set(Utc::now().naive_utc()),
                ..Default::default()
            };
            learning_materials::Entity::update(material)
                .exec(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to reorder material: {}", e)))?;
        }
        Ok(())
    }
}
