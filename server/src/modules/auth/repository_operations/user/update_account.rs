use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::users;

pub async fn update_account(
    db: &DatabaseConnection,
    user_id: Uuid,
    first_name: Option<String>,
    last_name: Option<String>,
    role: Option<String>,
) -> AppResult<users::Model> {
    let mut user: users::ActiveModel = users::Entity::find_by_id(user_id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("User not found".to_string()))?
        .into();

    if let Some(first_name) = first_name {
        user.first_name = Set(first_name);
    }
    if let Some(last_name) = last_name {
        user.last_name = Set(last_name);
    }
    if let Some(role) = role {
        user.role = Set(role);
    }
    user.updated_at = Set(Utc::now().naive_utc());

    user.update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update account: {}", e)))
}
