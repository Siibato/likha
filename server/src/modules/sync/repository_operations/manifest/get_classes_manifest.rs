use sea_orm::*;
use uuid::Uuid;

use ::entity::classes;
use crate::utils::{AppError, AppResult};
use super::ManifestEntry;

pub async fn get_classes_manifest(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
) -> AppResult<Vec<ManifestEntry>> {
    let records = classes::Entity::find()
        .filter(classes::Column::Id.is_in(class_ids))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    Ok(records
        .into_iter()
        .map(|r| ManifestEntry {
            id: r.id,
            updated_at: r.updated_at,
            deleted: false,
        })
        .collect())
}
