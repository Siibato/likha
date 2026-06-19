use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use ::entity::student_school_history;
use crate::utils::{AppError, AppResult};
use super::helpers;

pub async fn get_school_history_since(
    db: &DatabaseConnection,
    student_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    if student_ids.is_empty() { return Ok(vec![]); }
    let records = student_school_history::Entity::find()
        .filter(student_school_history::Column::StudentId.is_in(student_ids))
        .filter(student_school_history::Column::UpdatedAt.gt(since))
        .all(db).await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records.into_iter().map(helpers::school_history_to_json).collect())
}
