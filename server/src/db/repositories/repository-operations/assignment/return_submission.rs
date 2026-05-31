use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::assignment_submissions;
use crate::utils::{AppError, AppResult};

pub async fn return_submission(
    db: &DatabaseConnection,
    id: Uuid,
) -> AppResult<assignment_submissions::Model> {
    let mut submission: assignment_submissions::ActiveModel =
        assignment_submissions::Entity::find_by_id(id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?
            .into();

    submission.status = Set("returned".to_string());
    submission.updated_at = Set(Utc::now().naive_utc());

    submission
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to return submission: {}", e)))
}
