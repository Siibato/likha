use sea_orm::*;

use crate::utils::{AppError, AppResult};
use ::entity::assignments;

pub async fn find_all(db: &DatabaseConnection) -> AppResult<Vec<assignments::Model>> {
    assignments::Entity::find()
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
