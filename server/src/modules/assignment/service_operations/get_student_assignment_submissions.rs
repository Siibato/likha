use uuid::Uuid;
use crate::utils::{AppError, AppResult};
use crate::modules::assignment::schema::*;
use crate::modules::class::repository::ClassRepository;
use crate::modules::assignment::repository::AssignmentRepository;

pub async fn get_student_assignment_submissions(
    assignment_repo: &AssignmentRepository,
    class_repo: &ClassRepository,
    assignment_id: Uuid,
    student_id: Uuid,
    teacher_id: Uuid,
) -> AppResult<AssignmentSubmissionResponse> {
    let assignment = assignment_repo.find_by_id(assignment_id).await?
        .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

    if !class_repo.is_teacher_of_class(teacher_id, assignment.class_id).await? {
        return Err(AppError::Forbidden("Teacher access required".to_string()));
    }

    let submission = assignment_repo.find_student_submission(assignment_id, student_id).await?
        .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

    let student_name = assignment_repo.find_student_name(student_id).await?;
    let files = assignment_repo.find_files_by_submission(submission.id).await?;

    Ok(build_submission_response(submission, student_name, files))
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
