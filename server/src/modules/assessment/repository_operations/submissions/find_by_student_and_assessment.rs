use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assessment_submissions;

pub async fn find_by_student_and_assessment(
    db: &DatabaseConnection,
    student_id: Uuid,
    assessment_id: Uuid,
) -> AppResult<Option<assessment_submissions::Model>> {
    assessment_submissions::Entity::find()
        .filter(assessment_submissions::Column::UserId.eq(student_id))
        .filter(assessment_submissions::Column::AssessmentId.eq(assessment_id))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
