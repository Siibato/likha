use sea_orm::*;
use uuid::Uuid;

use ::entity::{answer_key_acceptable_answers, answer_keys};
use crate::utils::{AppError, AppResult};

pub async fn add_enumeration_item(
    db: &DatabaseConnection,
    question_id: Uuid,
    acceptable_answers: Vec<String>,
) -> AppResult<answer_keys::Model> {
    let new_key = answer_keys::ActiveModel {
        id: Set(Uuid::new_v4()),
        question_id: Set(question_id),
    };
    let inserted = new_key
        .insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to create answer key: {}", e)))?;

    for text in acceptable_answers {
        let answer = answer_key_acceptable_answers::ActiveModel {
            id: Set(Uuid::new_v4()),
            answer_key_id: Set(inserted.id),
            answer_text: Set(text.trim().to_lowercase()),
        };
        answer
            .insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to add enumeration answer: {}", e)))?;
    }
    Ok(inserted)
}
