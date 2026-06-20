use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use ::entity::assignments;
use crate::utils::{AppError, AppResult};

pub async fn get_assignments_since(
    db: &DatabaseConnection,
    assignment_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    let records = assignments::Entity::find()
        .filter(assignments::Column::Id.is_in(assignment_ids))
        .filter(assignments::Column::UpdatedAt.gt(since))
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
                "instructions": r.instructions,
                "total_points": r.total_points,
                "allows_text_submission": r.allows_text_submission,
                "allows_file_submission": r.allows_file_submission,
                "allowed_file_types": r.allowed_file_types,
                "max_file_size_mb": r.max_file_size_mb,
                "due_at": r.due_at.to_string(),
                "is_published": r.is_published,
                "order_index": r.order_index,
                "term_number": r.term_number,
                "component": r.component,
                "created_at": r.created_at.to_string(),
                "updated_at": r.updated_at.to_string(),
                "deleted_at": r.deleted_at.map(|d| d.to_string()),
            })
        })
        .collect();

    Ok(records)
}
