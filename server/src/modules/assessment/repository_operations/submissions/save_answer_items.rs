use sea_orm::*;
use uuid::Uuid;

use ::entity::submission_answer_items;
use crate::utils::{AppError, AppResult};

pub async fn save_answer_items(
    db: &DatabaseConnection,
    submission_answer_id: Uuid,
    items: Vec<(Option<Uuid>, Option<Uuid>, Option<String>, bool)>,
) -> AppResult<()> {
    submission_answer_items::Entity::delete_many()
        .filter(submission_answer_items::Column::SubmissionAnswerId.eq(submission_answer_id))
        .exec(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to clear answer items: {}", e)))?;

    for (answer_key_id, choice_id, answer_text, is_correct) in items {
        let item = submission_answer_items::ActiveModel {
            id: Set(Uuid::new_v4()),
            submission_answer_id: Set(submission_answer_id),
            answer_key_id: Set(answer_key_id),
            choice_id: Set(choice_id),
            answer_text: Set(answer_text),
            is_correct: Set(is_correct),
        };
        item.insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to save answer item: {}", e)))?;
    }

    Ok(())
}
