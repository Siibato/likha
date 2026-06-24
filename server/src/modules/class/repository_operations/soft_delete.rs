use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::classes;

pub async fn soft_delete(db: &DatabaseConnection, id: Uuid) -> AppResult<()> {
    let class = classes::ActiveModel {
        id: Set(id),
        deleted_at: Set(Some(Utc::now().naive_utc())),
        updated_at: Set(Utc::now().naive_utc()),
        ..Default::default()
    };

    classes::Entity::update(class)
        .exec(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to delete class: {}", e)))?;

    Ok(())
}
