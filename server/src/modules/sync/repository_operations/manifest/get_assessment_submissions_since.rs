use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assessment_submissions;

pub async fn get_assessment_submissions_since(
    db: &DatabaseConnection,
    _user_id: Uuid,
    submission_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    let records = assessment_submissions::Entity::find()
        .filter(assessment_submissions::Column::Id.is_in(submission_ids))
        .filter(assessment_submissions::Column::UpdatedAt.gt(since))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let records: Vec<Value> = records
        .into_iter()
        .map(|r| {
            serde_json::json!({
                "id": r.id.to_string(),
                "assessment_id": r.assessment_id.to_string(),
                "user_id": r.user_id.to_string(),
                "started_at": r.started_at.to_string(),
                "submitted_at": r.submitted_at.map(|d| d.to_string()),
                "total_points": r.total_points,
                "created_at": r.created_at.to_string(),
                "updated_at": r.updated_at.to_string(),
                "deleted_at": r.deleted_at.map(|d| d.to_string()),
            })
        })
        .collect();

    Ok(records)
}
