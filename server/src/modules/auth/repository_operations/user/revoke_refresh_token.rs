use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::refresh_tokens;

pub async fn revoke_refresh_token(db: &DatabaseConnection, token_id: Uuid) -> AppResult<()> {
    let token = refresh_tokens::ActiveModel {
        id: Set(token_id),
        revoked_at: Set(Some(Utc::now().naive_utc())),
        ..Default::default()
    };

    token
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to revoke token: {}", e)))?;

    Ok(())
}
