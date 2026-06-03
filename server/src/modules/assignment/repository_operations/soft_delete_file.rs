use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::submission_files;
use crate::utils::{AppError, AppResult};

pub async fn soft_delete_file(db: &DatabaseConnection, id: Uuid) -> AppResult<()> {
    let file = submission_files::ActiveModel {
        id: Set(id),
        deleted_at: Set(Some(Utc::now().naive_utc())),
        file_path: Set(None),
        file_hash: Set(None),
        ..Default::default()
    };

    submission_files::Entity::update(file)
        .exec(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to delete file: {}", e)))?;

    Ok(())
}
