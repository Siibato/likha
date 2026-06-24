use crate::modules::assignment::repository::AssignmentRepository;
use crate::modules::assignment::schema::*;
use crate::modules::assignment::service_operations::build_submission_response::build_submission_response;
use crate::modules::class::repository::ClassRepository;
use crate::utils::{AppError, AppResult};
use uuid::Uuid;

pub async fn get_student_assignment_submissions(
    assignment_repo: &AssignmentRepository,
    class_repo: &ClassRepository,
    assignment_id: Uuid,
    student_id: Uuid,
    teacher_id: Uuid,
) -> AppResult<AssignmentSubmissionResponse> {
    let assignment = assignment_repo
        .find_by_id(assignment_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

    if !class_repo
        .is_teacher_of_class(teacher_id, assignment.class_id)
        .await?
    {
        return Err(AppError::Forbidden("Teacher access required".to_string()));
    }

    let submission = assignment_repo
        .find_student_submission(assignment_id, student_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

    let (student_first_name, student_last_name) =
        assignment_repo.find_student_name(student_id).await?;
    let files = assignment_repo
        .find_files_by_submission(submission.id)
        .await?;

    Ok(build_submission_response(
        submission,
        student_first_name,
        student_last_name,
        files,
    ))
}
