use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use super::helpers;
use crate::utils::{AppError, AppResult};
use ::entity::{table_of_specifications, tos_competencies};

pub async fn get_tos_competencies_since(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    if class_ids.is_empty() {
        return Ok(vec![]);
    }

    let tos_ids = table_of_specifications::Entity::find()
        .filter(table_of_specifications::Column::ClassId.is_in(class_ids))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .into_iter()
        .map(|r| r.id)
        .collect::<Vec<Uuid>>();

    if tos_ids.is_empty() {
        return Ok(vec![]);
    }

    let records = tos_competencies::Entity::find()
        .filter(tos_competencies::Column::TosId.is_in(tos_ids))
        .filter(tos_competencies::Column::UpdatedAt.gt(since))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records
        .into_iter()
        .map(helpers::tos_competency_to_json)
        .collect())
}
