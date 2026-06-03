use sea_orm::*;
use uuid::Uuid;

use ::entity::assignment_submissions;
use crate::utils::{AppError, AppResult};
use super::ManifestEntry;

pub async fn get_all_assignment_submissions_manifest(
    db: &DatabaseConnection,
    assignment_ids: Vec<Uuid>,
) -> AppResult<Vec<ManifestEntry>> {
    let records = assignment_submissions::Entity::find()
        .filter(assignment_submissions::Column::AssignmentId.is_in(assignment_ids))
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
