use sea_orm::*;
use uuid::Uuid;

use ::entity::submission_answers;
use crate::utils::{AppError, AppResult};

pub async fn upsert_answer(
    db: &DatabaseConnection,
    submission_id: Uuid,
    question_id: Uuid,
    _answer_text: Option<String>,
) -> AppResult<submission_answers::Model> {
    let existing = submission_answers::Entity::find()
        .filter(submission_answers::Column::SubmissionId.eq(submission_id))
        .filter(submission_answers::Column::QuestionId.eq(question_id))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    if let Some(existing) = existing {
        Ok(existing)
    } else {
        let answer = submission_answers::ActiveModel {
            id: Set(Uuid::new_v4()),
            submission_id: Set(submission_id),
            question_id: Set(question_id),
            points: Set(0.0),
            overridden_by: Set(None),
            overridden_at: Set(None),
        };

        answer
            .insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to save answer: {}", e)))
    }
}
