use sea_orm::*;

use ::entity::assessments;
use crate::utils::{AppError, AppResult};

pub async fn find_all(db: &DatabaseConnection) -> AppResult<Vec<assessments::Model>> {
    assessments::Entity::find()
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
