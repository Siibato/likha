use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assignments;

pub async fn update_assignment(
    db: &DatabaseConnection,
    id: Uuid,
    title: Option<String>,
    instructions: Option<String>,
    total_points: Option<i32>,
    allows_text_submission: Option<bool>,
    allows_file_submission: Option<bool>,
    allowed_file_types: Option<Option<String>>,
    max_file_size_mb: Option<Option<i32>>,
    due_at: Option<chrono::NaiveDateTime>,
    term_number: Option<Option<i32>>,
    component: Option<Option<String>>,
) -> AppResult<assignments::Model> {
    let mut assignment: assignments::ActiveModel = assignments::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?
        .into();

    if let Some(title) = title {
        assignment.title = Set(title);
    }
    if let Some(instructions) = instructions {
        assignment.instructions = Set(instructions);
    }
    if let Some(total_points) = total_points {
        assignment.total_points = Set(total_points);
    }
    if let Some(text) = allows_text_submission {
        assignment.allows_text_submission = Set(text);
    }
    if let Some(file) = allows_file_submission {
        assignment.allows_file_submission = Set(file);
    }
    if let Some(allowed) = allowed_file_types {
        assignment.allowed_file_types = Set(allowed);
    }
    if let Some(max_size) = max_file_size_mb {
        assignment.max_file_size_mb = Set(max_size);
    }
    if let Some(due) = due_at {
        assignment.due_at = Set(due);
    }
    if let Some(q) = term_number {
        assignment.term_number = Set(q);
    }
    if let Some(c) = component {
        assignment.component = Set(c);
    }
    assignment.updated_at = Set(Utc::now().naive_utc());

    assignment
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update assignment: {}", e)))
}
