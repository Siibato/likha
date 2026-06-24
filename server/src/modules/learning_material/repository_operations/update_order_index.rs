use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::learning_materials;

pub async fn update_order_index(
    db: &DatabaseConnection,
    id: Uuid,
    order_index: i32,
) -> AppResult<learning_materials::Model> {
    let mut material: learning_materials::ActiveModel = learning_materials::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?
        .into();

    material.order_index = Set(order_index);
    material.updated_at = Set(Utc::now().naive_utc());

    material
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update order: {}", e)))
}
