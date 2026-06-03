use sea_orm::*;
use uuid::Uuid;

use ::entity::assessment_questions;
use crate::utils::{AppError, AppResult};

pub async fn delete_question(
    db: &DatabaseConnection,
    id: Uuid,
) -> AppResult<()> {
    assessment_questions::Entity::delete_by_id(id)
        .exec(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to delete question: {}", e)))?;
    Ok(())
}
