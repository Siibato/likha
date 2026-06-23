use crate::modules::assignment::repository::AssignmentRepository;
use crate::modules::assignment::schema::AssignmentSubmissionResponse;
use crate::modules::assignment::service_operations::build_submission_response::build_submission_response;
use crate::modules::class::repository::ClassRepository;
use crate::utils::{AppError, AppResult};
use uuid::Uuid;

pub async fn get_student_assignment_submission(
    assignment_repo: &AssignmentRepository,
    class_repo: &ClassRepository,
    assignment_id: Uuid,
    student_id: Uuid,
    user_id: Uuid,
    _role: &str,
) -> AppResult<Option<AssignmentSubmissionResponse>> {
    let assignment = assignment_repo
        .find_by_id(assignment_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

    let is_teacher = class_repo
        .is_teacher_of_class(user_id, assignment.class_id)
        .await?;
    let is_own = user_id == student_id;

    if !is_teacher && !is_own {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    let submission = assignment_repo
        .find_student_submission(assignment_id, student_id)
        .await?;

    let result = if let Some(sub) = submission {
        let (student_first_name, student_last_name) =
            assignment_repo.find_student_name(student_id).await?;
        let files = assignment_repo.find_files_by_submission(sub.id).await?;
        Some(build_submission_response(
            sub,
            student_first_name,
            student_last_name,
            files,
        ))
    } else {
        None
    };

    Ok(result)
}
