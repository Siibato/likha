use sea_orm::*;
use uuid::Uuid;

use ::entity::users;
use crate::utils::{AppError, AppResult};

pub async fn find_student_name(db: &DatabaseConnection, student_id: Uuid) -> AppResult<String> {
    let user = users::Entity::find_by_id(student_id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;
    Ok(user.full_name)
}
