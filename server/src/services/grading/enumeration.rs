use uuid::Uuid;
use crate::db::repositories::assessment_repository::AssessmentRepository;
use crate::db::repositories::submission_repository::SubmissionRepository;
use crate::utils::AppResult;

pub async fn grade_enumeration(
    _submission_answer_id: Uuid,
    _question_id: Uuid,
    _points: i32,
    _assessment_repo: &AssessmentRepository,
    _submission_repo: &SubmissionRepository,
) -> AppResult<(bool, f64)> {
    // Enumeration grading not currently supported - feature not in schema
    // TODO: Re-implement if schema is updated to support enumeration questions
    Ok((false, 0.0))
}