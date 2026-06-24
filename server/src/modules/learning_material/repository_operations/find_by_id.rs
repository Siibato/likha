use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::learning_materials;

pub async fn find_by_id(
    db: &DatabaseConnection,
    id: Uuid,
) -> AppResult<Option<learning_materials::Model>> {
    learning_materials::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
