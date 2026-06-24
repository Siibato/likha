use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::login_attempts;

pub async fn record_attempt(
    db: &DatabaseConnection,
    user_id: Option<Uuid>,
    success: bool,
    device_id: Option<String>,
) -> AppResult<()> {
    let now = chrono::Utc::now().naive_utc();
    let record = login_attempts::ActiveModel {
        id: Set(Uuid::new_v4()),
        user_id: Set(user_id),
        attempted_at: Set(now),
        success: Set(success),
        device_id: Set(device_id),
    };

    record.insert(db).await.map_err(|e| {
        AppError::InternalServerError(format!("Failed to create login attempt record: {}", e))
    })?;

    Ok(())
}
