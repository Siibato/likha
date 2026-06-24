use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assignment_submissions;

pub async fn create_submission(
    db: &DatabaseConnection,
    assignment_id: Uuid,
    student_id: Uuid,
    submission_id: Option<Uuid>,
) -> AppResult<assignment_submissions::Model> {
    let submission = assignment_submissions::ActiveModel {
        id: Set(submission_id.unwrap_or_else(Uuid::new_v4)),
        assignment_id: Set(assignment_id),
        student_id: Set(student_id),
        status: Set("draft".to_string()),
        text_content: Set(None),
        submitted_at: Set(None),
        points: Set(None),
        graded_by: Set(None),
        feedback: Set(None),
        graded_at: Set(None),
        created_at: Set(Utc::now().naive_utc()),
        updated_at: Set(Utc::now().naive_utc()),
        deleted_at: Set(None),
    };

    submission
        .insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to create submission: {}", e)))
}
