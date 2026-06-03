use sea_orm::*;
use uuid::Uuid;

use ::entity::assessment_questions;
use crate::utils::{AppError, AppResult};

pub async fn find_question_by_id(
    db: &DatabaseConnection,
    id: Uuid,
) -> AppResult<Option<assessment_questions::Model>> {
    assessment_questions::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
