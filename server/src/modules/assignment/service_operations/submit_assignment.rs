use uuid::Uuid;
use crate::utils::{AppError, AppResult};
use crate::modules::assignment::schema::*;
use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::modules::assignment::repository::AssignmentRepository;

pub async fn submit_assignment(
    assignment_repo: &AssignmentRepository,
    activity_log_repo: &ActivityLogRepository,
    submission_id: Uuid,
    student_id: Uuid,
    text_content: Option<String>,
) -> AppResult<AssignmentSubmissionResponse> {
    let submission = assignment_repo.find_submission_by_id(submission_id).await?
        .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

    if submission.student_id != student_id {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    let assignment = assignment_repo.find_by_id(submission.assignment_id).await?
        .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

    if submission.status != "draft" && submission.status != "returned" && submission.status != "submitted" {
        return Err(AppError::BadRequest(format!(
            "Cannot submit a submission with status '{}'", submission.status
        )));
    }

    if submission.status == "submitted" {
        let now = chrono::Utc::now().naive_utc();
        if now > assignment.due_at {
            return Err(AppError::BadRequest(
                "The deadline has passed. You can no longer resubmit.".to_string(),
            ));
        }
    }

    if text_content.is_some() {
        assignment_repo.update_submission_text(submission_id, text_content).await?;
    }

    let updated = assignment_repo.update_submission_status(submission_id, "submitted").await?;

    let _ = activity_log_repo.create_log(
        student_id,
        "assignment_submitted",
        Some(format!("Submitted assignment '{}'", assignment.title)),
    ).await;

    let student_name = assignment_repo.find_student_name(student_id).await?;
    let files = assignment_repo.find_files_by_submission(submission_id).await?;

    Ok(build_submission_response(updated, student_name, files))
}

pub fn build_submission_response(
    submission: ::entity::assignment_submissions::Model,
    student_name: String,
    files: Vec<::entity::submission_files::Model>,
) -> AssignmentSubmissionResponse {
    let file_responses: Vec<FileMetadataResponse> = files
        .into_iter()
        .map(|f| FileMetadataResponse {
            id: f.id,
            file_name: f.file_name,
            file_type: f.file_type,
            file_size: f.file_size,
            uploaded_at: f.uploaded_at.to_string(),
        })
        .collect();

    AssignmentSubmissionResponse {
        id: submission.id,
        assignment_id: submission.assignment_id,
        student_id: submission.student_id,
        student_name,
        status: submission.status,
        text_content: submission.text_content,
        submitted_at: submission.submitted_at.map(|dt| dt.to_string()),
        score: submission.points,
        feedback: submission.feedback,
        graded_at: submission.graded_at.map(|dt| dt.to_string()),
        files: file_responses,
        created_at: submission.created_at.to_string(),
        updated_at: submission.updated_at.to_string(),
    }
}
