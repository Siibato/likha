use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::assessment_submissions;
use crate::utils::{AppError, AppResult};

pub async fn create_submission(
    db: &DatabaseConnection,
    assessment_id: Uuid,
    student_id: Uuid,
    submission_id: Option<Uuid>,
) -> AppResult<assessment_submissions::Model> {
    let now = Utc::now().naive_utc();
    let submission = assessment_submissions::ActiveModel {
        id: Set(submission_id.unwrap_or_else(Uuid::new_v4)),
        assessment_id: Set(assessment_id),
        user_id: Set(student_id),
        started_at: Set(now),
        submitted_at: Set(None),
        total_points: Set(0.0),
        created_at: Set(now),
        updated_at: Set(now),
        deleted_at: Set(None),
    };

    submission
        .insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to create submission: {}", e)))
}
