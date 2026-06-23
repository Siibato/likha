use chrono::Duration;
use sea_orm::*;

use crate::utils::{AppError, AppResult};
use ::entity::login_attempts;

pub async fn clear_all_attempts(db: &DatabaseConnection) -> AppResult<()> {
    let thirty_days_ago = chrono::Utc::now().naive_utc() - Duration::days(30);
    login_attempts::Entity::delete_many()
        .filter(login_attempts::Column::AttemptedAt.lt(thirty_days_ago))
        .exec(db)
        .await
        .map_err(|e| {
            AppError::InternalServerError(format!("Failed to clear old attempts: {}", e))
        })?;
    Ok(())
}
