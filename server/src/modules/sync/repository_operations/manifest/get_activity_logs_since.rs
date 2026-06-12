use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use ::entity::activity_logs;
use crate::utils::{AppError, AppResult};

pub async fn get_activity_logs_since(
    db: &DatabaseConnection,
    log_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    if log_ids.is_empty() {
        return Ok(vec![]);
    }

    let records = activity_logs::Entity::find()
        .filter(activity_logs::Column::Id.is_in(log_ids.clone()))
        .filter(activity_logs::Column::CreatedAt.gt(since))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let records: Vec<Value> = records
        .into_iter()
        .map(|r| {
            serde_json::json!({
                "id": r.id.to_string(),
                "user_id": r.user_id.to_string(),
                "action": r.action,
                "details": r.details,
                "created_at": r.created_at.to_string(),
            })
        })
        .collect();

    Ok(records)
}
