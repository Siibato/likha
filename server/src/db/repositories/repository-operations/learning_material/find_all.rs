use sea_orm::*;

use ::entity::learning_materials;
use crate::utils::{AppError, AppResult};

pub async fn find_all(db: &DatabaseConnection) -> AppResult<Vec<learning_materials::Model>> {
    learning_materials::Entity::find()
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
