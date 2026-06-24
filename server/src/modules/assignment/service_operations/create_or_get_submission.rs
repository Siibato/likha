use crate::modules::assignment::repository::AssignmentRepository;
use crate::modules::assignment::schema::*;
use crate::modules::assignment::service_operations::build_submission_response::build_submission_response;
use crate::modules::class::repository::ClassRepository;
use crate::utils::{AppError, AppResult};
use uuid::Uuid;

pub async fn create_or_get_submission(
    assignment_repo: &AssignmentRepository,
    class_repo: &ClassRepository,
    assignment_id: Uuid,
    student_id: Uuid,
    client_submission_id: Option<Uuid>,
) -> AppResult<AssignmentSubmissionResponse> {
    let assignment = assignment_repo
        .find_by_id(assignment_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

    if !assignment.is_published {
        return Err(AppError::NotFound("Assignment not found".to_string()));
    }

    let enrolled = class_repo
        .is_student_enrolled(assignment.class_id, student_id)
        .await?;
    if !enrolled {
        return Err(AppError::Forbidden(
            "You are not enrolled in this class".to_string(),
        ));
    }

    let submission = match assignment_repo
        .find_student_submission(assignment_id, student_id)
        .await?
    {
        Some(existing) => {
            if existing.status == "graded" {
                return Err(AppError::BadRequest(
                    "This submission has already been graded".to_string(),
                ));
            }
            if existing.status == "submitted" {
                let now = chrono::Utc::now().naive_utc();
                if now > assignment.due_at {
                    return Err(AppError::BadRequest(
                        "The deadline has passed. You can no longer edit this submission."
                            .to_string(),
                    ));
                }
            }
            existing
        }
        None => {
            assignment_repo
                .create_submission(assignment_id, student_id, client_submission_id)
                .await?
        }
    };

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
