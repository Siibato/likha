use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assessment_submissions;

pub async fn count_submissions_by_assessment_id(
    db: &DatabaseConnection,
    assessment_id: Uuid,
) -> AppResult<usize> {
    let count = assessment_submissions::Entity::find()
        .filter(assessment_submissions::Column::AssessmentId.eq(assessment_id))
        .count(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(count as usize)
}
