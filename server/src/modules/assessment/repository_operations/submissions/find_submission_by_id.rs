use sea_orm::*;
use uuid::Uuid;

use ::entity::assessment_submissions;
use crate::utils::{AppError, AppResult};

pub async fn find_submission_by_id(
    db: &DatabaseConnection,
    id: Uuid,
) -> AppResult<Option<assessment_submissions::Model>> {
    assessment_submissions::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
