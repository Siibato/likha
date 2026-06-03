use sea_orm::*;

use ::entity::users;
use crate::utils::{AppError, AppResult};

pub async fn find_by_username(db: &DatabaseConnection, username: &str) -> AppResult<Option<users::Model>> {
    users::Entity::find()
        .filter(users::Column::Username.eq(username))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
