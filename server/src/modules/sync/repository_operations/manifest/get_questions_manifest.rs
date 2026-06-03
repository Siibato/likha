use sea_orm::*;
use uuid::Uuid;

use ::entity::assessment_questions;
use crate::utils::{AppError, AppResult};
use super::ManifestEntry;

pub async fn get_questions_manifest(
    db: &DatabaseConnection,
    assessment_ids: Vec<Uuid>,
) -> AppResult<Vec<ManifestEntry>> {
    let records = assessment_questions::Entity::find()
        .filter(assessment_questions::Column::AssessmentId.is_in(assessment_ids))
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
