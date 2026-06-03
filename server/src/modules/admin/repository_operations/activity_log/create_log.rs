use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::activity_logs;
use crate::utils::{AppError, AppResult};

pub async fn create_log(
    db: &DatabaseConnection,
    user_id: Uuid,
    action: &str,
    details: Option<String>,
) -> AppResult<activity_logs::Model> {
    let log = activity_logs::ActiveModel {
        id: Set(Uuid::new_v4()),
        user_id: Set(user_id),
        action: Set(action.to_string()),
        details: Set(details),
        created_at: Set(Utc::now().naive_utc()),
    };

    log.insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to create activity log: {}", e)))
}
