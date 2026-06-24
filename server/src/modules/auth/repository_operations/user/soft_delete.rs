use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::users;

pub async fn soft_delete(db: &DatabaseConnection, user_id: Uuid) -> AppResult<()> {
    let now = Utc::now().naive_utc();
    let user = users::ActiveModel {
        id: Set(user_id),
        deleted_at: Set(Some(now)),
        updated_at: Set(now),
        ..Default::default()
    };

    user.update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to delete account: {}", e)))?;

    Ok(())
}
