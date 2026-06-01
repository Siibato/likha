use sea_orm::*;
use uuid::Uuid;

use ::entity::material_files;
use crate::utils::{AppError, AppResult};

pub async fn count_active_by_hash(db: &DatabaseConnection, hash: &str, exclude_id: Uuid) -> AppResult<i64> {
    let count = material_files::Entity::find()
        .filter(material_files::Column::FileHash.eq(hash))
        .filter(material_files::Column::DeletedAt.is_null())
        .filter(material_files::Column::Id.ne(exclude_id))
        .count(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    Ok(count as i64)
}
