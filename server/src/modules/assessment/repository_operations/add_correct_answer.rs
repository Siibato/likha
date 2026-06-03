use sea_orm::*;
use uuid::Uuid;

use ::entity::{answer_key_acceptable_answers, answer_keys};
use crate::utils::{AppError, AppResult};

pub async fn add_correct_answer(
    db: &DatabaseConnection,
    question_id: Uuid,
    answer_text: String,
) -> AppResult<answer_key_acceptable_answers::Model> {
    let answer_key = answer_keys::Entity::find()
        .filter(answer_keys::Column::QuestionId.eq(question_id))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let answer_key_id = if let Some(key) = answer_key {
        key.id
    } else {
        let new_key = answer_keys::ActiveModel {
            id: Set(Uuid::new_v4()),
            question_id: Set(question_id),
        };
        let inserted = new_key
            .insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create answer key: {}", e)))?;
        inserted.id
    };

    let answer = answer_key_acceptable_answers::ActiveModel {
        id: Set(Uuid::new_v4()),
        answer_key_id: Set(answer_key_id),
        answer_text: Set(answer_text.trim().to_lowercase()),
    };

    answer
        .insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to add correct answer: {}", e)))
}
