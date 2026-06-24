use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assessment_submissions;

pub async fn update_submission_scores(
    db: &DatabaseConnection,
    submission_id: Uuid,
    total_points: f64,
) -> AppResult<()> {
    let mut submission: assessment_submissions::ActiveModel =
        assessment_submissions::Entity::find_by_id(submission_id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?
            .into();

    submission.total_points = Set(total_points);

    submission
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update scores: {}", e)))?;

    Ok(())
}
