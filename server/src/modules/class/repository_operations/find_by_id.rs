use sea_orm::*;
use uuid::Uuid;

use ::entity::classes;
use crate::utils::{AppError, AppResult};

pub async fn find_by_id(db: &DatabaseConnection, id: Uuid) -> AppResult<Option<classes::Model>> {
    classes::Entity::find_by_id(id)
        .filter(classes::Column::DeletedAt.is_null())
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
