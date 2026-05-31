use sea_orm::*;
use uuid::Uuid;

use ::entity::assignments;
use crate::utils::{AppError, AppResult};

pub async fn find_by_id(
    db: &DatabaseConnection,
    id: Uuid,
) -> AppResult<Option<assignments::Model>> {
    assignments::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
