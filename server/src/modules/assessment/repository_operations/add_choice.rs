use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::question_choices;

pub async fn add_choice(
    db: &DatabaseConnection,
    question_id: Uuid,
    choice_text: String,
    is_correct: bool,
    order_index: i32,
    client_id: Option<Uuid>,
) -> AppResult<question_choices::Model> {
    let now = Utc::now().naive_utc();
    let choice = question_choices::ActiveModel {
        id: Set(client_id.unwrap_or_else(Uuid::new_v4)),
        question_id: Set(question_id),
        choice_text: Set(choice_text),
        is_correct: Set(is_correct),
        order_index: Set(order_index),
        updated_at: Set(now),
    };

    choice
        .insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to add choice: {}", e)))
}
