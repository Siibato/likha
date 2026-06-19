use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use ::entity::previous_school_subjects;
use crate::utils::{AppError, AppResult};
use super::helpers;

pub async fn get_previous_subjects_since(
    db: &DatabaseConnection,
    student_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    if student_ids.is_empty() { return Ok(vec![]); }
    let records = previous_school_subjects::Entity::find()
        .filter(previous_school_subjects::Column::StudentId.is_in(student_ids))
        .filter(previous_school_subjects::Column::UpdatedAt.gt(since))
        .all(db).await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records.into_iter().map(helpers::previous_school_subject_to_json).collect())
}
