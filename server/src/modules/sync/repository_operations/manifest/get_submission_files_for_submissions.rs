use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::submission_files;

pub async fn get_submission_files_for_submissions(
    db: &DatabaseConnection,
    submission_ids: Vec<Uuid>,
) -> AppResult<Vec<Value>> {
    let files = submission_files::Entity::find()
        .filter(submission_files::Column::SubmissionId.is_in(submission_ids))
        .all(db)
        .await
        .map_err(|e| {
            AppError::InternalServerError(format!("Failed to fetch submission files: {}", e))
        })?;
    Ok(files
        .into_iter()
        .map(|f| {
            serde_json::json!({
                "id": f.id.to_string(),
                "submission_id": f.submission_id.to_string(),
                "file_name": f.file_name,
                "file_type": f.file_type,
                "file_size": f.file_size,
                "uploaded_at": f.uploaded_at.to_string(),
            })
        })
        .collect())
}
