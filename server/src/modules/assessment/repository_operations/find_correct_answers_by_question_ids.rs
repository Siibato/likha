use sea_orm::*;
use uuid::Uuid;

use ::entity::{answer_key_acceptable_answers, answer_keys};
use crate::utils::{AppError, AppResult};
use std::collections::HashMap;

pub async fn find_correct_answers_by_question_ids(
    db: &DatabaseConnection,
    question_ids: &[Uuid],
) -> AppResult<HashMap<Uuid, Vec<answer_key_acceptable_answers::Model>>> {
    if question_ids.is_empty() {
        return Ok(HashMap::new());
    }

    // Find all answer_keys for the given question_ids
    let keys = answer_keys::Entity::find()
        .filter(answer_keys::Column::QuestionId.is_in(question_ids.iter().copied()))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to fetch answer keys: {}", e)))?;

    if keys.is_empty() {
        return Ok(HashMap::new());
    }

    let key_ids: Vec<Uuid> = keys.iter().map(|k| k.id).collect();
    let key_to_question: HashMap<Uuid, Uuid> = keys.iter().map(|k| (k.id, k.question_id)).collect();

    // Batch fetch all acceptable answers for those answer_keys
    let answers = answer_key_acceptable_answers::Entity::find()
        .filter(answer_key_acceptable_answers::Column::AnswerKeyId.is_in(key_ids))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to fetch acceptable answers: {}", e)))?;

    let mut result: HashMap<Uuid, Vec<answer_key_acceptable_answers::Model>> = HashMap::new();
    for answer in answers {
        if let Some(&question_id) = key_to_question.get(&answer.answer_key_id) {
            result.entry(question_id).or_default().push(answer);
        }
    }

    Ok(result)
}
