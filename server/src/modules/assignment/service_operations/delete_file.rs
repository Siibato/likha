use std::path::PathBuf;
use uuid::Uuid;
use crate::utils::{AppError, AppResult};
use crate::modules::assignment::repository::AssignmentRepository;
use crate::services::file_service;

pub async fn delete_file(
    assignment_repo: &AssignmentRepository,
    file_id: Uuid,
    student_id: Uuid,
) -> AppResult<()> {
    let file = assignment_repo.find_file_by_id(file_id).await?
        .ok_or_else(|| AppError::NotFound("File not found".to_string()))?;

    let submission = assignment_repo.find_submission_by_id(file.submission_id).await?
        .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

    if submission.student_id != student_id {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    if submission.status != "draft" && submission.status != "returned" && submission.status != "submitted" {
        return Err(AppError::BadRequest(
            "Can only delete files from draft, returned, or submitted (before deadline) submissions".to_string(),
        ));
    }

    if submission.status == "submitted" {
        let assignment = assignment_repo.find_by_id(submission.assignment_id).await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;
        let now = chrono::Utc::now().naive_utc();
        if now > assignment.due_at {
            return Err(AppError::BadRequest(
                "The deadline has passed. You can no longer delete files.".to_string(),
            ));
        }
    }

    assignment_repo.soft_delete_file(file_id).await?;

    if let (Some(hash), Some(path)) = (file.file_hash, file.file_path) {
        if let Ok(count) = assignment_repo.count_active_by_hash(&hash, file_id).await {
            if count == 0 {
                file_service::delete_file(&PathBuf::from(&path)).await;
            }
        }
    }

    Ok(())
}
