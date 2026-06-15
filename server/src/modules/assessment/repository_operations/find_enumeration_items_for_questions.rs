use sea_orm::*;
use uuid::Uuid;

use ::entity::{answer_key_acceptable_answers, answer_keys};
use crate::utils::{AppError, AppResult};
use std::collections::HashMap;

pub async fn find_enumeration_items_for_questions(
    db: &DatabaseConnection,
    question_ids: &[Uuid],
) -> AppResult<HashMap<Uuid, Vec<(answer_keys::Model, Vec<answer_key_acceptable_answers::Model>)>>> {
    if question_ids.is_empty() {
        return Ok(HashMap::new());
    }

    // Find all answer_keys for the given question_ids
    let keys = answer_keys::Entity::find()
        .filter(answer_keys::Column::QuestionId.is_in(question_ids.iter().copied()))
        .order_by_asc(answer_keys::Column::QuestionId)
        .order_by_asc(answer_keys::Column::Id)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to fetch answer keys: {}", e)))?;

    if keys.is_empty() {
        return Ok(HashMap::new());
    }

    let key_ids: Vec<Uuid> = keys.iter().map(|k| k.id).collect();

    // Batch fetch all acceptable answers
    let answers = answer_key_acceptable_answers::Entity::find()
        .filter(answer_key_acceptable_answers::Column::AnswerKeyId.is_in(key_ids))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to fetch acceptable answers: {}", e)))?;

    let mut answers_by_key: HashMap<Uuid, Vec<answer_key_acceptable_answers::Model>> = HashMap::new();
    for answer in answers {
        answers_by_key.entry(answer.answer_key_id).or_default().push(answer);
    }

    let mut result: HashMap<Uuid, Vec<(answer_keys::Model, Vec<answer_key_acceptable_answers::Model>)>> = HashMap::new();
    for key in keys {
        let answers = answers_by_key.remove(&key.id).unwrap_or_default();
        result.entry(key.question_id).or_default().push((key, answers));
    }

    Ok(result)
}
