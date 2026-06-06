use sea_orm::*;
use uuid::Uuid;

use ::entity::material_files;
use crate::utils::{AppError, AppResult};
use std::collections::HashMap;

pub async fn count_files_by_materials(
    db: &DatabaseConnection,
    material_ids: &[Uuid],
) -> AppResult<HashMap<Uuid, usize>> {
    if material_ids.is_empty() {
        return Ok(HashMap::new());
    }

    let rows: Vec<(Uuid, i64)> = material_files::Entity::find()
        .select_only()
        .column(material_files::Column::MaterialId)
        .column_as(material_files::Column::Id.count(), "count")
        .filter(material_files::Column::MaterialId.is_in(material_ids.iter().copied()))
        .group_by(material_files::Column::MaterialId)
        .into_tuple()
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    Ok(rows.into_iter().map(|(id, count)| (id, count as usize)).collect())
}
