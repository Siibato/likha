use sea_orm::*;

use ::entity::material_files;
use crate::utils::{AppError, AppResult};

pub async fn find_active_file_path_by_hash(db: &DatabaseConnection, hash: &str) -> AppResult<Option<String>> {
    let result = material_files::Entity::find()
        .filter(material_files::Column::FileHash.eq(hash))
        .filter(material_files::Column::DeletedAt.is_null())
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    Ok(result.and_then(|f| f.file_path))
}
