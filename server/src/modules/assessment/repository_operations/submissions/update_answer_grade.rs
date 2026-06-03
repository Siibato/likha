use sea_orm::*;
use uuid::Uuid;

use ::entity::submission_answers;
use crate::utils::{AppError, AppResult};

pub async fn update_answer_grade(
    db: &DatabaseConnection,
    answer_id: Uuid,
    _is_auto_correct: Option<bool>,
    points_awarded: f64,
) -> AppResult<submission_answers::Model> {
    let mut answer: submission_answers::ActiveModel =
        submission_answers::Entity::find_by_id(answer_id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Answer not found".to_string()))?
            .into();

    answer.points = Set(points_awarded);

    answer
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update answer grade: {}", e)))
}
