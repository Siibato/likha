use std::path::PathBuf;
use uuid::Uuid;
use crate::utils::{AppError, AppResult};
use crate::modules::assignment::repository::AssignmentRepository;
use crate::utils::file_service;

pub async fn download_file(
    assignment_repo: &AssignmentRepository,
    file_encryption_key: &[u8; 32],
    file_id: Uuid,
    user_id: Uuid,
) -> AppResult<(String, String, Vec<u8>)> {
    let file = assignment_repo.find_file_by_id(file_id).await?
        .ok_or_else(|| AppError::NotFound("File not found".to_string()))?;

    let submission = assignment_repo.find_submission_by_id(file.submission_id).await?
        .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

    if submission.student_id != user_id {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    let file_path = file.file_path
        .ok_or_else(|| AppError::NotFound("File data not available".to_string()))?;

    let file_bytes = file_service::read_file(&PathBuf::from(&file_path), Some(file_encryption_key))
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to read file from disk: {}", e)))?;

    Ok((file.file_name, file.file_type, file_bytes))
}
