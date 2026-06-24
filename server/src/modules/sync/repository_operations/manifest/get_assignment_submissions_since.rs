use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assignment_submissions;

pub async fn get_assignment_submissions_since(
    db: &DatabaseConnection,
    _user_id: Uuid,
    submission_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    let records = assignment_submissions::Entity::find()
        .filter(assignment_submissions::Column::Id.is_in(submission_ids))
        .filter(assignment_submissions::Column::UpdatedAt.gt(since))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let records: Vec<Value> = records
        .into_iter()
        .map(|r| {
            serde_json::json!({
                "id": r.id.to_string(),
                "assignment_id": r.assignment_id.to_string(),
                "student_id": r.student_id.to_string(),
                "status": r.status,
                "text_content": r.text_content,
                "submitted_at": r.submitted_at.map(|d| d.to_string()),
                "points": r.points,
                "feedback": r.feedback,
                "graded_at": r.graded_at.map(|d| d.to_string()),
                "graded_by": r.graded_by.map(|id| id.to_string()),
                "created_at": r.created_at.to_string(),
                "updated_at": r.updated_at.to_string(),
                "deleted_at": r.deleted_at.map(|d| d.to_string()),
            })
        })
        .collect();

    Ok(records)
}
