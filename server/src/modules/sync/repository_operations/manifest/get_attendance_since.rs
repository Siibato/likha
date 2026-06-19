use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use ::entity::attendance_records;
use crate::utils::{AppError, AppResult};
use super::helpers;

pub async fn get_attendance_since(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    if class_ids.is_empty() { return Ok(vec![]); }
    let records = attendance_records::Entity::find()
        .filter(attendance_records::Column::ClassId.is_in(class_ids))
        .filter(attendance_records::Column::UpdatedAt.gt(since))
        .all(db).await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records.into_iter().map(helpers::attendance_record_to_json).collect())
}
