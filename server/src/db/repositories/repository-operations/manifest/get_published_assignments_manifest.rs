use sea_orm::*;
use uuid::Uuid;

use ::entity::assignments;
use crate::utils::{AppError, AppResult};
use super::ManifestEntry;

pub async fn get_published_assignments_manifest(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
) -> AppResult<Vec<ManifestEntry>> {
    let records = assignments::Entity::find()
        .filter(assignments::Column::ClassId.is_in(class_ids))
        .filter(assignments::Column::IsPublished.eq(true))
        .filter(assignments::Column::DeletedAt.is_null())
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
