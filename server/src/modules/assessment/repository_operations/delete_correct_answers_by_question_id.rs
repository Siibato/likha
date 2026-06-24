use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::answer_keys;

pub async fn delete_correct_answers_by_question_id(
    db: &DatabaseConnection,
    question_id: Uuid,
) -> AppResult<()> {
    let answer_key = answer_keys::Entity::find()
        .filter(answer_keys::Column::QuestionId.eq(question_id))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    if let Some(key) = answer_key {
        answer_keys::Entity::delete_by_id(key.id)
            .exec(db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!("Failed to delete answer key: {}", e))
            })?;
    }
    Ok(())
}
