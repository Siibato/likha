use sea_orm::*;
use uuid::Uuid;

use ::entity::submission_answer_items;
use crate::utils::{AppError, AppResult};

pub async fn find_answer_items_by_submission_answer_id(
    db: &DatabaseConnection,
    submission_answer_id: Uuid,
) -> AppResult<Vec<submission_answer_items::Model>> {
    submission_answer_items::Entity::find()
        .filter(submission_answer_items::Column::SubmissionAnswerId.eq(submission_answer_id))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
