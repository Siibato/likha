use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::grade_items;

pub async fn find_item(db: &DatabaseConnection, id: Uuid) -> AppResult<Option<grade_items::Model>> {
    grade_items::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
