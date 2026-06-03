use sea_orm::*;
use uuid::Uuid;

use ::entity::assessment_submissions;
use crate::utils::{AppError, AppResult};

pub async fn find_submissions_by_assessment_id(
    db: &DatabaseConnection,
    assessment_id: Uuid,
) -> AppResult<Vec<assessment_submissions::Model>> {
    assessment_submissions::Entity::find()
        .filter(assessment_submissions::Column::AssessmentId.eq(assessment_id))
        .order_by_desc(assessment_submissions::Column::CreatedAt)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
