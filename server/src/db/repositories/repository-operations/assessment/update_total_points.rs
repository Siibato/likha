use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::{assessment_questions, assessments};
use crate::utils::{AppError, AppResult};

pub async fn update_total_points(
    db: &DatabaseConnection,
    assessment_id: Uuid,
) -> AppResult<()> {
    let questions = assessment_questions::Entity::find()
        .filter(assessment_questions::Column::AssessmentId.eq(assessment_id))
        .order_by_asc(assessment_questions::Column::OrderIndex)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let total: i32 = questions.iter().map(|q| q.points).sum();

    let mut assessment: assessments::ActiveModel = assessments::Entity::find_by_id(assessment_id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?
        .into();

    assessment.total_points = Set(total);
    assessment.updated_at = Set(Utc::now().naive_utc());

    assessment
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update total points: {}", e)))?;

    Ok(())
}
