use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assessment_submissions;

pub async fn find_submission_by_id(
    db: &DatabaseConnection,
    id: Uuid,
) -> AppResult<Option<assessment_submissions::Model>> {
    assessment_submissions::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
