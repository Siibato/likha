use sea_orm::*;

use crate::utils::{AppError, AppResult};
use ::entity::refresh_tokens;

pub async fn find_refresh_token(
    db: &DatabaseConnection,
    token_hash: &str,
) -> AppResult<Option<refresh_tokens::Model>> {
    refresh_tokens::Entity::find()
        .filter(refresh_tokens::Column::TokenHash.eq(token_hash))
        .filter(refresh_tokens::Column::RevokedAt.is_null())
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
