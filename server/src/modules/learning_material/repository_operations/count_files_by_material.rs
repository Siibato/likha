use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::material_files;

pub async fn count_files_by_material(
    db: &DatabaseConnection,
    material_id: Uuid,
) -> AppResult<usize> {
    let count = material_files::Entity::find()
        .filter(material_files::Column::MaterialId.eq(material_id))
        .filter(material_files::Column::DeletedAt.is_null())
        .count(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    Ok(count as usize)
}
