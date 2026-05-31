use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use ::entity::grade_record;
use crate::utils::{AppError, AppResult};
use super::helpers;

pub async fn get_grade_configs_for_classes(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
) -> AppResult<Vec<Value>> {
    if class_ids.is_empty() { return Ok(vec![]); }
    let records = grade_record::Entity::find()
        .filter(grade_record::Column::ClassId.is_in(class_ids))
        .all(db).await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records.into_iter().map(helpers::grade_config_to_json).collect())
}
