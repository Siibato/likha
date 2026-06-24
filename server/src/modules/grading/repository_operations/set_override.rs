use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::grade_scores;

pub async fn set_override(
    db: &DatabaseConnection,
    id: Uuid,
    override_score: f64,
) -> AppResult<grade_scores::Model> {
    let mut score: grade_scores::ActiveModel = grade_scores::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("Grade score not found".to_string()))?
        .into();

    score.override_score = Set(Some(override_score));
    score.updated_at = Set(Utc::now().naive_utc());

    score
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to set override: {}", e)))
}
