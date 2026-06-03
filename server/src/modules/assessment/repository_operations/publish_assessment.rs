use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::assessments;
use crate::utils::{AppError, AppResult};

pub async fn publish_assessment(
    db: &DatabaseConnection,
    id: Uuid,
) -> AppResult<assessments::Model> {
    let mut assessment: assessments::ActiveModel = assessments::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?
        .into();

    assessment.is_published = Set(true);
    assessment.updated_at = Set(Utc::now().naive_utc());

    assessment
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to publish assessment: {}", e)))
}
