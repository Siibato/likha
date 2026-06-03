use sea_orm::*;
use uuid::Uuid;

use ::entity::submission_answer_items;
use crate::utils::{AppError, AppResult};

pub async fn update_answer_item_correctness(
    db: &DatabaseConnection,
    item_id: Uuid,
    is_correct: bool,
) -> AppResult<()> {
    let mut item: submission_answer_items::ActiveModel =
        submission_answer_items::Entity::find_by_id(item_id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Answer item not found".to_string()))?
            .into();

    item.is_correct = Set(is_correct);

    item.update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update answer item: {}", e)))?;

    Ok(())
}
