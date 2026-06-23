use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use super::helpers;
use crate::utils::{AppError, AppResult};
use ::entity::teacher_details;

pub async fn get_teacher_details_since(
    db: &DatabaseConnection,
    teacher_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    if teacher_ids.is_empty() {
        return Ok(vec![]);
    }
    let records = teacher_details::Entity::find()
        .filter(teacher_details::Column::UserId.is_in(teacher_ids))
        .filter(teacher_details::Column::UpdatedAt.gt(since))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records
        .into_iter()
        .map(helpers::teacher_details_to_json)
        .collect())
}
