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
        // Partial credit for multi-select: correct_selected / total_correct * points
        let correct_selected = selected_ids.intersection(&correct_ids).count();
        let total_correct = correct_ids.len();
        let awarded = if total_correct > 0 {
            (correct_selected as f64 / total_correct as f64) * points as f64
        } else {
            0.0
        };
        let is_any_correct = correct_selected > 0;
        Ok((is_any_correct, awarded))
    } else {
        // Single-select: unchanged (all-or-nothing)
        let is_correct = selected_ids.len() == 1 && correct_ids == selected_ids;
        let awarded = if is_correct { points as f64 } else { 0.0 };
        Ok((is_correct, awarded))
    }
}