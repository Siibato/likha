use sea_orm::*;
use uuid::Uuid;

use ::entity::submission_files;
use crate::utils::{AppError, AppResult};

pub async fn find_file_by_id(
    db: &DatabaseConnection,
    id: Uuid,
) -> AppResult<Option<submission_files::Model>> {
    submission_files::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
