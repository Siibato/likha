use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use super::helpers;
use crate::utils::{AppError, AppResult};
use ::entity::previous_school_term_grades;

pub async fn get_previous_school_term_grades_since(
    db: &DatabaseConnection,
    subject_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    if subject_ids.is_empty() {
        return Ok(vec![]);
    }
    let records = previous_school_term_grades::Entity::find()
        .filter(previous_school_term_grades::Column::SubjectId.is_in(subject_ids))
        .filter(previous_school_term_grades::Column::UpdatedAt.gt(since))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records
        .into_iter()
        .map(helpers::previous_school_term_grade_to_json)
        .collect())
}
