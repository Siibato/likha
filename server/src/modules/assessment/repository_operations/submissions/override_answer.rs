use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::submission_answers;
use crate::utils::{AppError, AppResult};

pub async fn override_answer(
    db: &DatabaseConnection,
    answer_id: Uuid,
    _is_correct: bool,
    points: f64,
    teacher_id: Uuid,
) -> AppResult<submission_answers::Model> {
    let mut answer: submission_answers::ActiveModel =
        submission_answers::Entity::find_by_id(answer_id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Answer not found".to_string()))?
            .into();

    answer.points = Set(points);
    answer.overridden_by = Set(Some(teacher_id));
    answer.overridden_at = Set(Some(Utc::now().naive_utc()));

    answer
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to override answer: {}", e)))
}
