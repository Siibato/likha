use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assignment_submissions;

pub async fn update_submission_status(
    db: &DatabaseConnection,
    id: Uuid,
    status: &str,
) -> AppResult<assignment_submissions::Model> {
    let mut submission: assignment_submissions::ActiveModel =
        assignment_submissions::Entity::find_by_id(id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?
            .into();

    submission.status = Set(status.to_string());
    if status == "submitted" {
        submission.submitted_at = Set(Some(Utc::now().naive_utc()));
    }
    submission.updated_at = Set(Utc::now().naive_utc());

    submission.update(db).await.map_err(|e| {
        AppError::InternalServerError(format!("Failed to update submission status: {}", e))
    })
}
