use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::grade_items;
use crate::utils::{AppError, AppResult};

pub async fn update_item(
    db: &DatabaseConnection,
    id: Uuid,
    title: Option<String>,
    component: Option<String>,
    total_points: Option<f64>,
    order_index: Option<i32>,
    source_type: Option<String>,
    source_id: Option<String>,
) -> AppResult<grade_items::Model> {
    let mut item: grade_items::ActiveModel = grade_items::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("Grade item not found".to_string()))?
        .into();

    if let Some(title) = title { item.title = Set(title); }
    if let Some(component) = component { item.component = Set(component); }
    if let Some(total_points) = total_points { item.total_points = Set(total_points); }
    if let Some(order_index) = order_index { item.order_index = Set(order_index); }
    if let Some(source_type) = source_type { item.source_type = Set(source_type); }
    if let Some(source_id) = source_id { item.source_id = Set(Some(source_id)); }
    item.updated_at = Set(Utc::now().naive_utc());

    item.update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update grade item: {}", e)))
}
