use sea_orm::*;
use uuid::Uuid;

use ::entity::material_files;
use crate::utils::{AppError, AppResult};

pub async fn count_files_by_material(db: &DatabaseConnection, material_id: Uuid) -> AppResult<usize> {
    let count = material_files::Entity::find()
        .filter(material_files::Column::MaterialId.eq(material_id))
        .count(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    Ok(count as usize)
}
