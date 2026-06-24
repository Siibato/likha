use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assessments;

pub async fn get_assessments_since(
    db: &DatabaseConnection,
    assessment_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    let records = assessments::Entity::find()
        .filter(assessments::Column::Id.is_in(assessment_ids))
        .filter(assessments::Column::UpdatedAt.gt(since))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let records: Vec<Value> = records
        .into_iter()
        .map(|r| {
            serde_json::json!({
                "id": r.id.to_string(),
                "class_id": r.class_id.to_string(),
                "title": r.title,
                "description": r.description,
                "time_limit_minutes": r.time_limit_minutes,
                "open_at": r.open_at.to_string(),
                "close_at": r.close_at.to_string(),
                "show_results_immediately": r.show_results_immediately,
                "is_published": r.is_published,
                "results_released": r.results_released,
                "order_index": r.order_index,
                "total_points": r.total_points,
                "created_at": r.created_at.to_string(),
                "updated_at": r.updated_at.to_string(),
                "deleted_at": r.deleted_at.map(|d| d.to_string()),
            })
        })
        .collect();

    Ok(records)
}
