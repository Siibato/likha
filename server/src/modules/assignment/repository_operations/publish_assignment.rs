use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::assignments;
use crate::utils::{AppError, AppResult};

pub async fn publish_assignment(
    db: &DatabaseConnection,
    id: Uuid,
) -> AppResult<assignments::Model> {
    let mut assignment: assignments::ActiveModel = assignments::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?
        .into();

    assignment.is_published = Set(true);
    assignment.updated_at = Set(Utc::now().naive_utc());

    assignment
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to publish assignment: {}", e)))
}
