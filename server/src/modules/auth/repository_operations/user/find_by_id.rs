use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::users;

pub async fn find_by_id(db: &DatabaseConnection, id: Uuid) -> AppResult<Option<users::Model>> {
    users::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
