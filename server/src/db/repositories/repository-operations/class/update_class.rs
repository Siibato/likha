use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::classes;
use crate::utils::{AppError, AppResult};

pub async fn update_class(
    db: &DatabaseConnection,
    id: Uuid,
    title: Option<String>,
    description: Option<Option<String>>,
    is_advisory: Option<bool>,
) -> AppResult<classes::Model> {
    let class = classes::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

    let mut active_class: classes::ActiveModel = class.into();
    active_class.updated_at = Set(Utc::now().naive_utc());

    if let Some(title) = title {
        active_class.title = Set(title);
    }
    if let Some(description) = description {
        active_class.description = Set(description);
    }
    if let Some(is_advisory) = is_advisory {
        active_class.is_advisory = Set(is_advisory);
    }

    active_class
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update class: {}", e)))
}
