use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use ::entity::table_of_specifications;
use crate::utils::{AppError, AppResult};
use super::helpers;

pub async fn get_table_of_specifications_since(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    if class_ids.is_empty() { return Ok(vec![]); }
    let records = table_of_specifications::Entity::find()
        .filter(table_of_specifications::Column::ClassId.is_in(class_ids))
        .filter(table_of_specifications::Column::UpdatedAt.gt(since))
        .all(db).await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records.into_iter().map(helpers::tos_to_json).collect())
}
