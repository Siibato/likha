use crate::modules::assignment::repository::AssignmentRepository;
use crate::modules::assignment::schema::*;
use crate::modules::assignment::service_operations::build_submission_response::build_submission_response;
use crate::modules::class::repository::ClassRepository;
use crate::utils::{AppError, AppResult};
use uuid::Uuid;

pub async fn get_submission_detail(
    assignment_repo: &AssignmentRepository,
    class_repo: &ClassRepository,
    submission_id: Uuid,
    user_id: Uuid,
    role: &str,
) -> AppResult<AssignmentSubmissionResponse> {
    let submission = assignment_repo
        .find_submission_by_id(submission_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

    let assignment = assignment_repo
        .find_by_id(submission.assignment_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

    if role == "teacher" {
        if !class_repo
            .is_teacher_of_class(user_id, assignment.class_id)
            .await?
        {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }
    } else if submission.student_id != user_id {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    let (student_first_name, student_last_name) = assignment_repo
        .find_student_name(submission.student_id)
        .await?;
    let files = assignment_repo
        .find_files_by_submission(submission_id)
        .await?;

    Ok(build_submission_response(
        submission,
        student_first_name,
        student_last_name,
        files,
    ))
}
