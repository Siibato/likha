use sea_orm::*;

use crate::utils::{AppError, AppResult};
use ::entity::submission_files;

pub async fn find_active_file_path_by_hash(
    db: &DatabaseConnection,
    hash: &str,
) -> AppResult<Option<String>> {
    let result = submission_files::Entity::find()
        .filter(submission_files::Column::FileHash.eq(hash))
        .filter(submission_files::Column::DeletedAt.is_null())
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    Ok(result.and_then(|f| f.file_path))
}
