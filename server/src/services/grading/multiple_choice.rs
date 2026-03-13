use uuid::Uuid;
use crate::db::repositories::assessment_repository::AssessmentRepository;
use crate::db::repositories::submission_repository::SubmissionRepository;
use crate::utils::AppResult;

pub async fn grade_multiple_choice(
    submission_answer_id: Uuid,
    question_id: Uuid,
    points: i32,
    is_multi_select: bool,
    assessment_repo: &AssessmentRepository,
    submission_repo: &SubmissionRepository,
) -> AppResult<(bool, f64)> {
    let choices = assessment_repo.find_choices_by_question_id(question_id).await?;
    let selected = submission_repo.find_answer_choices(submission_answer_id).await?;

    let correct_ids: std::collections::HashSet<Uuid> = choices
        .iter()
        .filter(|c| c.is_correct)
        .map(|c| c.id)
        .collect();

    let selected_ids: std::collections::HashSet<Uuid> =
        selected.iter().cloned().collect();

    if is_multi_select {
        let is_correct = correct_ids == selected_ids;
        let awarded = if is_correct { points as f64 } else { 0.0 };
        Ok((is_correct, awarded))
    } else {
        let is_correct = selected_ids.len() == 1 && correct_ids == selected_ids;
        let awarded = if is_correct { points as f64 } else { 0.0 };
        Ok((is_correct, awarded))
    }
}