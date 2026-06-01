use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::table_of_specifications;
use crate::utils::{AppError, AppResult};

pub async fn soft_delete_tos(db: &DatabaseConnection, id: Uuid) -> AppResult<()> {
    let tos = table_of_specifications::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

    let mut active: table_of_specifications::ActiveModel = tos.into();
    let now = Utc::now().naive_utc();
    active.deleted_at = Set(Some(now));
    active.updated_at = Set(now);

    active
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to delete TOS: {}", e)))?;

    Ok(())
}
