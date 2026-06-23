use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use super::helpers;
use crate::utils::{AppError, AppResult};
use ::entity::tos_competencies;

pub async fn get_tos_competencies_for_tos_ids(
    db: &DatabaseConnection,
    tos_ids: Vec<Uuid>,
) -> AppResult<Vec<Value>> {
    if tos_ids.is_empty() {
        return Ok(vec![]);
    }
    let records = tos_competencies::Entity::find()
        .filter(tos_competencies::Column::TosId.is_in(tos_ids))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records
        .into_iter()
        .map(helpers::tos_competency_to_json)
        .collect())
}
