use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use ::entity::grade_scores;
use crate::utils::{AppError, AppResult};
use super::helpers;

pub async fn get_student_grade_scores_since(
    db: &DatabaseConnection,
    student_id: Uuid,
    grade_item_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    if grade_item_ids.is_empty() { return Ok(vec![]); }
    let records = grade_scores::Entity::find()
        .filter(grade_scores::Column::GradeItemId.is_in(grade_item_ids))
        .filter(grade_scores::Column::StudentId.eq(student_id))
        .filter(grade_scores::Column::UpdatedAt.gt(since))
        .all(db).await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records.into_iter().map(helpers::grade_score_to_json).collect())
}
