use uuid::Uuid;
use crate::utils::{AppError, AppResult};
use crate::modules::assignment::schema::*;
use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::modules::class::repository::ClassRepository;
use crate::db::repositories::grade_computation_repository::GradeComputationRepository;
use crate::modules::assignment::repository::AssignmentRepository;
use crate::services::grade_computation::auto_populate;

pub async fn grade_submission(
    assignment_repo: &AssignmentRepository,
    class_repo: &ClassRepository,
    activity_log_repo: &ActivityLogRepository,
    grade_computation_repo: &GradeComputationRepository,
    submission_id: Uuid,
    request: GradeSubmissionRequest,
    teacher_id: Uuid,
) -> AppResult<AssignmentSubmissionResponse> {
    let submission = assignment_repo.find_submission_by_id(submission_id).await?
        .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

    let assignment = assignment_repo.find_by_id(submission.assignment_id).await?
        .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

    let _class = class_repo.find_by_id(assignment.class_id).await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

    if !class_repo.is_teacher_of_class(teacher_id, assignment.class_id).await? {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    if submission.status != "submitted" && submission.status != "returned" && submission.status != "graded" {
        return Err(AppError::BadRequest(format!(
            "Cannot grade a submission with status '{}'",
            submission.status
        )));
    }

    if request.score < 0 || request.score > assignment.total_points {
        return Err(AppError::BadRequest(format!(
            "Score must be between 0 and {}",
            assignment.total_points
        )));
    }

    if let Some(ref feedback) = request.feedback {
        if feedback.len() > 5000 {
            return Err(AppError::BadRequest(
                "Feedback must be at most 5000 characters".to_string(),
            ));
        }
    }

    let graded = assignment_repo.grade_submission(
        submission_id, request.score, request.feedback, Some(teacher_id),
    ).await?;

    let _ = auto_populate::auto_populate_score(
        grade_computation_repo, "assignment", submission.assignment_id, submission.student_id, request.score as f64,
    ).await;

    let _ = activity_log_repo.create_log(
        teacher_id,
        "assignment_graded",
        Some(format!(
            "Graded assignment '{}' - score: {}/{}",
            assignment.title, request.score, assignment.total_points
        )),
    ).await;

    let student_name = assignment_repo.find_student_name(graded.student_id).await?;
    let files = assignment_repo.find_files_by_submission(submission_id).await?;

    Ok(build_submission_response(graded, student_name, files))
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
