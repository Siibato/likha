use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::{answer_key_acceptable_answers, answer_keys};

pub async fn find_enumeration_items_for_question(
    db: &DatabaseConnection,
    question_id: Uuid,
) -> AppResult<
    Vec<(
        answer_keys::Model,
        Vec<answer_key_acceptable_answers::Model>,
    )>,
> {
    let keys = answer_keys::Entity::find()
        .filter(answer_keys::Column::QuestionId.eq(question_id))
        .all(db)
        .await
        .map_err(|e| {
            AppError::InternalServerError(format!("Failed to fetch answer keys: {}", e))
        })?;

    let mut result = Vec::new();
    for key in keys {
        let answers = answer_key_acceptable_answers::Entity::find()
            .filter(answer_key_acceptable_answers::Column::AnswerKeyId.eq(key.id))
            .all(db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!("Failed to fetch acceptable answers: {}", e))
            })?;
        result.push((key, answers));
    }
    Ok(result)
}
