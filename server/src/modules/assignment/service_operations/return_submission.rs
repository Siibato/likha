use crate::modules::admin::ActivityLogRepository;
use crate::modules::assignment::repository::AssignmentRepository;
use crate::modules::assignment::schema::*;
use crate::modules::assignment::service_operations::build_submission_response::build_submission_response;
use crate::modules::class::repository::ClassRepository;
use crate::utils::{AppError, AppResult};
use uuid::Uuid;

pub async fn return_submission(
    assignment_repo: &AssignmentRepository,
    class_repo: &ClassRepository,
    activity_log_repo: &ActivityLogRepository,
    submission_id: Uuid,
    teacher_id: Uuid,
) -> AppResult<AssignmentSubmissionResponse> {
    let submission = assignment_repo
        .find_submission_by_id(submission_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

    let assignment = assignment_repo
        .find_by_id(submission.assignment_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

    let _class = class_repo
        .find_by_id(assignment.class_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

    if !class_repo
        .is_teacher_of_class(teacher_id, assignment.class_id)
        .await?
    {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    if submission.status != "submitted" {
        return Err(AppError::BadRequest(
            "Can only return submitted submissions".to_string(),
        ));
    }

    let returned = assignment_repo.return_submission(submission_id).await?;

    let _ = activity_log_repo
        .create_log(
            teacher_id,
            "assignment_returned",
            Some(format!(
                "Returned assignment '{}' for revision",
                assignment.title
            )),
        )
        .await;

    let (student_first_name, student_last_name) = assignment_repo
        .find_student_name(returned.student_id)
        .await?;
    let files = assignment_repo
        .find_files_by_submission(submission_id)
        .await?;

    Ok(build_submission_response(
        returned,
        student_first_name,
        student_last_name,
        files,
    ))
}
