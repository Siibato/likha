use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::users;

pub async fn set_password(
    db: &DatabaseConnection,
    user_id: Uuid,
    password_hash: String,
) -> AppResult<users::Model> {
    let user = users::ActiveModel {
        id: Set(user_id),
        password_hash: Set(Some(password_hash)),
        account_status: Set("activated".to_string()),
        activated_at: Set(Some(Utc::now().naive_utc())),
        updated_at: Set(Utc::now().naive_utc()),
        ..Default::default()
    };

    user.update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to set password: {}", e)))
}
