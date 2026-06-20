use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use ::entity::period_grades;
use crate::utils::{AppError, AppResult};
use super::helpers;

pub async fn get_all_period_grades_since(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    if class_ids.is_empty() { return Ok(vec![]); }
    let records = period_grades::Entity::find()
        .filter(period_grades::Column::ClassId.is_in(class_ids))
        .filter(period_grades::Column::UpdatedAt.gt(since))
        .all(db).await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records.into_iter().map(helpers::period_grade_to_json).collect())
}
