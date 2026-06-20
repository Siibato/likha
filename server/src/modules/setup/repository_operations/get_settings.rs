use sea_orm::*;

use ::entity::school_details;
use crate::utils::{AppError, AppResult};

pub async fn get_settings(db: &DatabaseConnection) -> AppResult<school_details::Model> {
    school_details::Entity::find_by_id(1)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::InternalServerError("School settings not initialized".to_string()))
}
