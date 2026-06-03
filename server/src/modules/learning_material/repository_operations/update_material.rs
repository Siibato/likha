use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::learning_materials;
use crate::utils::{AppError, AppResult};

pub async fn update_material(
    db: &DatabaseConnection,
    id: Uuid,
    title: Option<String>,
    description: Option<Option<String>>,
    content_text: Option<Option<String>>,
) -> AppResult<learning_materials::Model> {
    let mut material: learning_materials::ActiveModel = learning_materials::Entity::find_by_id(id)
        .one(db)
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
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update material: {}", e)))
}
