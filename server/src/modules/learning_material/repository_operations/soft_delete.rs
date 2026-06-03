use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::learning_materials;
use crate::utils::{AppError, AppResult};

pub async fn soft_delete(db: &DatabaseConnection, id: Uuid) -> AppResult<()> {
    let material = learning_materials::ActiveModel {
        id: Set(id),
        deleted_at: Set(Some(Utc::now().naive_utc())),
        updated_at: Set(Utc::now().naive_utc()),
        ..Default::default()
    };

    learning_materials::Entity::update(material)
        .exec(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to delete material: {}", e)))?;

    Ok(())
}
