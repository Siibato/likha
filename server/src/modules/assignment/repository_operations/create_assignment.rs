use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assignments;

pub async fn create_assignment(
    db: &DatabaseConnection,
    class_id: Uuid,
    title: String,
    instructions: String,
    total_points: i32,
    allows_text_submission: bool,
    allows_file_submission: bool,
    allowed_file_types: Option<String>,
    max_file_size_mb: Option<i32>,
    due_at: chrono::NaiveDateTime,
    order_index: i32,
    client_id: Option<Uuid>,
    is_published: bool,
    term_number: Option<i32>,
    component: Option<String>,
) -> AppResult<assignments::Model> {
    let assignment = assignments::ActiveModel {
        id: Set(client_id.unwrap_or_else(Uuid::new_v4)),
        class_id: Set(class_id),
        title: Set(title),
        instructions: Set(instructions),
        total_points: Set(total_points),
        allows_text_submission: Set(allows_text_submission),
        allows_file_submission: Set(allows_file_submission),
        allowed_file_types: Set(allowed_file_types),
        max_file_size_mb: Set(max_file_size_mb),
        due_at: Set(due_at),
        is_published: Set(is_published),
        order_index: Set(order_index),
        created_at: Set(Utc::now().naive_utc()),
        updated_at: Set(Utc::now().naive_utc()),
        deleted_at: Set(None),
        term_number: Set(term_number),
        component: Set(component),
    };

    assignment
        .insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to create assignment: {}", e)))
}
