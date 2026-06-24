use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assessment_questions;

pub async fn reorder_questions(
    db: &DatabaseConnection,
    _assessment_id: Uuid,
    question_ids: Vec<Uuid>,
) -> AppResult<()> {
    for (index, id) in question_ids.iter().enumerate() {
        let question = assessment_questions::ActiveModel {
            id: Set(*id),
            order_index: Set(index as i32),
            updated_at: Set(Utc::now().naive_utc()),
            ..Default::default()
        };
        assessment_questions::Entity::update(question)
            .exec(db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!("Failed to reorder question: {}", e))
            })?;
    }

    Ok(())
}
