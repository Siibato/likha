use sea_orm::*;
use uuid::Uuid;

use ::entity::submission_answers;
use crate::utils::{AppError, AppResult};

pub async fn find_answer_by_id(
    db: &DatabaseConnection,
    id: Uuid,
) -> AppResult<Option<submission_answers::Model>> {
    submission_answers::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
