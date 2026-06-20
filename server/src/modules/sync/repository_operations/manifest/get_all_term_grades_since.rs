use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use ::entity::term_grades;
use crate::utils::{AppError, AppResult};
use super::helpers;

pub async fn get_all_term_grades_since(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    if class_ids.is_empty() { return Ok(vec![]); }
    let records = term_grades::Entity::find()
        .filter(term_grades::Column::ClassId.is_in(class_ids))
        .filter(term_grades::Column::UpdatedAt.gt(since))
        .all(db).await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records.into_iter().map(helpers::period_grade_to_json).collect())
}
