use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assessment_submissions;

pub async fn mark_submitted(
    db: &DatabaseConnection,
    submission_id: Uuid,
) -> AppResult<assessment_submissions::Model> {
    let mut submission: assessment_submissions::ActiveModel =
        assessment_submissions::Entity::find_by_id(submission_id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?
            .into();

    submission.submitted_at = Set(Some(Utc::now().naive_utc()));

    submission
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to submit: {}", e)))
}
