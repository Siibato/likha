use sea_orm::*;
use uuid::Uuid;

use ::entity::answer_keys;
use crate::utils::{AppError, AppResult};

pub async fn delete_all_answer_keys_for_question(
    db: &DatabaseConnection,
    question_id: Uuid,
) -> AppResult<()> {
    let keys = answer_keys::Entity::find()
        .filter(answer_keys::Column::QuestionId.eq(question_id))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    for key in keys {
        answer_keys::Entity::delete_by_id(key.id)
            .exec(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to delete answer key: {}", e)))?;
    }
    Ok(())
}
