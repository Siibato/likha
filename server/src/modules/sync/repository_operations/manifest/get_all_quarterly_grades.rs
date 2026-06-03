use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use ::entity::period_grades;
use crate::utils::{AppError, AppResult};
use super::helpers;

pub async fn get_all_quarterly_grades(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
) -> AppResult<Vec<Value>> {
    if class_ids.is_empty() { return Ok(vec![]); }
    let records = period_grades::Entity::find()
        .filter(period_grades::Column::ClassId.is_in(class_ids))
        .all(db).await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records.into_iter().map(helpers::quarterly_grade_to_json).collect())
}
