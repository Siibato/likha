use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::tos_competencies;
use crate::utils::{AppError, AppResult};

pub async fn soft_delete_competency(db: &DatabaseConnection, id: Uuid) -> AppResult<()> {
    let comp = tos_competencies::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("Competency not found".to_string()))?;

    let mut active: tos_competencies::ActiveModel = comp.into();
    let now = Utc::now().naive_utc();
    active.deleted_at = Set(Some(now));
    active.updated_at = Set(now);

    active
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to delete competency: {}", e)))?;

    Ok(())
}
