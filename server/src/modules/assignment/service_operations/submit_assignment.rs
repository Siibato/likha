use uuid::Uuid;
use crate::utils::{AppError, AppResult};
use crate::modules::assignment::schema::*;
use crate::modules::admin::ActivityLogRepository;
use crate::modules::assignment::repository::AssignmentRepository;
use crate::modules::assignment::service_operations::build_submission_response::build_submission_response;

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

    let (student_first_name, student_last_name) = assignment_repo.find_student_name(student_id).await?;
    let files = assignment_repo.find_files_by_submission(submission_id).await?;

    Ok(build_submission_response(updated, student_first_name, student_last_name, files))
}
