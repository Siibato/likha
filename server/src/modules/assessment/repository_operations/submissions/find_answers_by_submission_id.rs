use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::submission_answers;

pub async fn find_answers_by_submission_id(
    db: &DatabaseConnection,
    submission_id: Uuid,
) -> AppResult<Vec<submission_answers::Model>> {
    submission_answers::Entity::find()
        .filter(submission_answers::Column::SubmissionId.eq(submission_id))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
