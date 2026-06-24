use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::{answer_key_acceptable_answers, answer_keys};

pub async fn find_correct_answers_by_question_id(
    db: &DatabaseConnection,
    question_id: Uuid,
) -> AppResult<Vec<answer_key_acceptable_answers::Model>> {
    let answer_key = answer_keys::Entity::find()
        .filter(answer_keys::Column::QuestionId.eq(question_id))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    if let Some(key) = answer_key {
        answer_key_acceptable_answers::Entity::find()
            .filter(answer_key_acceptable_answers::Column::AnswerKeyId.eq(key.id))
            .all(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    } else {
        Ok(vec![])
    }
}
