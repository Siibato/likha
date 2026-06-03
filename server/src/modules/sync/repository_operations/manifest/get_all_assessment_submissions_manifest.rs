use sea_orm::*;
use uuid::Uuid;

use ::entity::assessment_submissions;
use crate::utils::{AppError, AppResult};
use super::ManifestEntry;

pub async fn get_all_assessment_submissions_manifest(
    db: &DatabaseConnection,
    assessment_ids: Vec<Uuid>,
) -> AppResult<Vec<ManifestEntry>> {
    let records = assessment_submissions::Entity::find()
        .filter(assessment_submissions::Column::AssessmentId.is_in(assessment_ids))
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
