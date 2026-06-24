use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::learning_materials;

pub async fn create_material(
    db: &DatabaseConnection,
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
        .insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to create material: {}", e)))
}
