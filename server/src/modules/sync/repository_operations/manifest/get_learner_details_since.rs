use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use ::entity::learner_details;
use crate::utils::{AppError, AppResult};
use super::helpers;

pub async fn get_learner_details_since(
    db: &DatabaseConnection,
    student_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    if student_ids.is_empty() { return Ok(vec![]); }
    let records = learner_details::Entity::find()
        .filter(learner_details::Column::UserId.is_in(student_ids))
        .filter(learner_details::Column::UpdatedAt.gt(since))
        .all(db).await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records.into_iter().map(helpers::learner_details_to_json).collect())
}
