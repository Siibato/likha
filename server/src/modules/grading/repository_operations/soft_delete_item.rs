use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::grade_items;

pub async fn soft_delete_item(db: &DatabaseConnection, id: Uuid) -> AppResult<()> {
    let mut item: grade_items::ActiveModel = grade_items::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("Grade item not found".to_string()))?
        .into();

    item.deleted_at = Set(Some(Utc::now().naive_utc()));
    item.updated_at = Set(Utc::now().naive_utc());

    item.update(db).await.map_err(|e| {
        AppError::InternalServerError(format!("Failed to soft delete grade item: {}", e))
    })?;

    Ok(())
}
