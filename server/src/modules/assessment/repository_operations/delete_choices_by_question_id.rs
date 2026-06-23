use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::question_choices;

pub async fn delete_choices_by_question_id(
    db: &DatabaseConnection,
    question_id: Uuid,
) -> AppResult<()> {
    question_choices::Entity::delete_many()
        .filter(question_choices::Column::QuestionId.eq(question_id))
        .exec(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to delete choices: {}", e)))?;
    Ok(())
}
