use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::refresh_tokens;
use crate::utils::{AppError, AppResult};

pub async fn create_refresh_token(
    db: &DatabaseConnection,
    user_id: Uuid,
    token_hash: String,
    device_id: Option<String>,
    expires_at: chrono::NaiveDateTime,
) -> AppResult<refresh_tokens::Model> {
    let refresh_token = refresh_tokens::ActiveModel {
        id: Set(Uuid::new_v4()),
        user_id: Set(user_id),
        token_hash: Set(token_hash),
        device_id: Set(device_id),
        expires_at: Set(expires_at),
        created_at: Set(Utc::now().naive_utc()),
        revoked_at: Set(None),
    };

    refresh_token
        .insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to create refresh token: {}", e)))
}
