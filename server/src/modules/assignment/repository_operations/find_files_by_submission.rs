use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::submission_files;

pub async fn find_files_by_submission(
    db: &DatabaseConnection,
    submission_id: Uuid,
) -> AppResult<Vec<submission_files::Model>> {
    submission_files::Entity::find()
        .filter(submission_files::Column::SubmissionId.eq(submission_id))
        .filter(submission_files::Column::DeletedAt.is_null())
        .order_by_asc(submission_files::Column::UploadedAt)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
