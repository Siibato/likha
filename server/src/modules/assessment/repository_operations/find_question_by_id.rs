use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assessment_questions;

pub async fn find_question_by_id(
    db: &DatabaseConnection,
    id: Uuid,
) -> AppResult<Option<assessment_questions::Model>> {
    assessment_questions::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
