use sea_orm::*;
use uuid::Uuid;

use ::entity::assessment_questions;
use crate::utils::{AppError, AppResult};

pub async fn find_questions_by_assessment_id(
    db: &DatabaseConnection,
    assessment_id: Uuid,
) -> AppResult<Vec<assessment_questions::Model>> {
    assessment_questions::Entity::find()
        .filter(assessment_questions::Column::AssessmentId.eq(assessment_id))
        .order_by_asc(assessment_questions::Column::OrderIndex)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
