use sea_orm::*;

use crate::utils::{AppError, AppResult};
use ::entity::login_attempts;

pub async fn clear_attempts(db: &DatabaseConnection, username: &str, ip: &str) -> AppResult<()> {
    let device_id = format!("{}-{}", username, ip);

    login_attempts::Entity::delete_many()
        .filter(login_attempts::Column::DeviceId.eq(&device_id))
        .filter(login_attempts::Column::Success.eq(false))
        .exec(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to clear attempts: {}", e)))?;

    Ok(())
}
