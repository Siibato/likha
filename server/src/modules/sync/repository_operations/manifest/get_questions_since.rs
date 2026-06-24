use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assessment_questions;

pub async fn get_questions_since(
    db: &DatabaseConnection,
    question_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    let records = assessment_questions::Entity::find()
        .filter(assessment_questions::Column::Id.is_in(question_ids))
        .filter(assessment_questions::Column::UpdatedAt.gt(since))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let records: Vec<Value> = records
        .into_iter()
        .map(|r| {
            serde_json::json!({
                "id": r.id.to_string(),
                "assessment_id": r.assessment_id.to_string(),
                "question_type": r.question_type,
                "question_text": r.question_text,
                "points": r.points,
                "order_index": r.order_index,
                "is_multi_select": r.is_multi_select,
                "updated_at": r.updated_at.to_string(),
                "deleted_at": r.deleted_at.map(|d| d.to_string()),
            })
        })
        .collect();

    Ok(records)
}
