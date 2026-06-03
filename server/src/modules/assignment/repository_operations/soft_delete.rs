use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::assignments;
use crate::utils::{AppError, AppResult};

pub async fn soft_delete(db: &DatabaseConnection, id: Uuid) -> AppResult<()> {
    let assignment = assignments::ActiveModel {
        id: Set(id),
        deleted_at: Set(Some(Utc::now().naive_utc())),
        updated_at: Set(Utc::now().naive_utc()),
        ..Default::default()
    };

    assignments::Entity::update(assignment)
        .exec(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to delete assignment: {}", e)))?;

    Ok(())
}
