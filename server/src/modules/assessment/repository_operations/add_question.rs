use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assessment_questions;

pub async fn add_question(
    db: &DatabaseConnection,
    assessment_id: Uuid,
    question_type: String,
    question_text: String,
    points: i32,
    order_index: i32,
    is_multi_select: bool,
    client_id: Option<Uuid>,
) -> AppResult<assessment_questions::Model> {
    let question = assessment_questions::ActiveModel {
        id: Set(client_id.unwrap_or_else(Uuid::new_v4)),
        assessment_id: Set(assessment_id),
        question_type: Set(question_type),
        question_text: Set(question_text),
        points: Set(points),
        order_index: Set(order_index),
        is_multi_select: Set(is_multi_select),
        created_at: Set(Utc::now().naive_utc()),
        updated_at: Set(Utc::now().naive_utc()),
        deleted_at: Set(None),
        tos_competency_id: Set(None),
        cognitive_level: Set(None),
        difficulty: Set(None),
    };

    question
        .insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to add question: {}", e)))
}
