use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assignment_submissions;

pub async fn update_submission_text(
    db: &DatabaseConnection,
    id: Uuid,
    text_content: Option<String>,
) -> AppResult<assignment_submissions::Model> {
    let mut submission: assignment_submissions::ActiveModel =
        assignment_submissions::Entity::find_by_id(id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?
            .into();

    submission.text_content = Set(text_content);
    submission.updated_at = Set(Utc::now().naive_utc());

    submission
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update submission: {}", e)))
}
