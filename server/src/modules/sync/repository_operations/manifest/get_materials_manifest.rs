use sea_orm::*;
use uuid::Uuid;

use ::entity::learning_materials;
use crate::utils::{AppError, AppResult};
use super::ManifestEntry;

pub async fn get_materials_manifest(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
) -> AppResult<Vec<ManifestEntry>> {
    let records = learning_materials::Entity::find()
        .filter(learning_materials::Column::ClassId.is_in(class_ids))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    Ok(records
        .into_iter()
        .map(|r| ManifestEntry {
            id: r.id,
            updated_at: r.updated_at,
            deleted: r.deleted_at.is_some(),
        })
        .collect())
}
