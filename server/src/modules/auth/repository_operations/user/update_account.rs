use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::users;
use crate::utils::{AppError, AppResult};

pub async fn update_account(
    db: &DatabaseConnection,
    user_id: Uuid,
    full_name: Option<String>,
    role: Option<String>,
) -> AppResult<users::Model> {
    let mut user: users::ActiveModel = users::Entity::find_by_id(user_id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("User not found".to_string()))?
        .into();

    if let Some(full_name) = full_name {
        user.full_name = Set(full_name);
    }
    if let Some(role) = role {
        user.role = Set(role);
    }
    user.updated_at = Set(Utc::now().naive_utc());

    user.update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update account: {}", e)))
}
