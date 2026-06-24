use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use super::helpers;
use crate::utils::{AppError, AppResult};
use ::entity::grade_scores;

pub async fn get_all_grade_scores(
    db: &DatabaseConnection,
    grade_item_ids: Vec<Uuid>,
) -> AppResult<Vec<Value>> {
    if grade_item_ids.is_empty() {
        return Ok(vec![]);
    }
    let records = grade_scores::Entity::find()
        .filter(grade_scores::Column::GradeItemId.is_in(grade_item_ids))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records
        .into_iter()
        .map(helpers::grade_score_to_json)
        .collect())
}
