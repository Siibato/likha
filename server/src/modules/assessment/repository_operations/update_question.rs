use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assessment_questions;

pub async fn update_question(
    db: &DatabaseConnection,
    id: Uuid,
    question_text: Option<String>,
    points: Option<i32>,
    order_index: Option<i32>,
    is_multi_select: Option<bool>,
) -> AppResult<assessment_questions::Model> {
    let mut question: assessment_questions::ActiveModel =
        assessment_questions::Entity::find_by_id(id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Question not found".to_string()))?
            .into();

    if let Some(text) = question_text {
        question.question_text = Set(text);
    }
    if let Some(pts) = points {
        question.points = Set(pts);
    }
    if let Some(idx) = order_index {
        question.order_index = Set(idx);
    }
    if let Some(ms) = is_multi_select {
        question.is_multi_select = Set(ms);
    }

    question
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update question: {}", e)))
}
