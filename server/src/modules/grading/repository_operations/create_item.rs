use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::grade_items;

pub async fn create_item(
    db: &DatabaseConnection,
    class_id: Uuid,
    title: String,
    component: String,
    term_number: Option<i32>,
    total_points: f64,
    source_type: String,
    source_id: Option<String>,
    order_index: i32,
) -> AppResult<grade_items::Model> {
    let item = grade_items::ActiveModel {
        id: Set(Uuid::new_v4()),
        class_id: Set(class_id),
        title: Set(title),
        component: Set(component),
        term_number: Set(term_number),
        total_points: Set(total_points),
        source_type: Set(source_type),
        source_id: Set(source_id),
        order_index: Set(order_index),
        created_at: Set(Utc::now().naive_utc()),
        updated_at: Set(Utc::now().naive_utc()),
        deleted_at: Set(None),
    };

    item.insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to create grade item: {}", e)))
}
