use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::users;

pub async fn clear_password(db: &DatabaseConnection, user_id: Uuid) -> AppResult<users::Model> {
    let user = users::ActiveModel {
        id: Set(user_id),
        password_hash: Set(None),
        account_status: Set("pending_activation".to_string()),
        activated_at: Set(None),
        updated_at: Set(Utc::now().naive_utc()),
        ..Default::default()
    };

    user.update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to clear password: {}", e)))
}
