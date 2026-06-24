use crate::modules::assessment::repository::AssessmentRepository;
use crate::utils::AppResult;
use uuid::Uuid;

pub async fn grade_multiple_choice(
    submission_answer_id: Uuid,
    question_id: Uuid,
    points: i32,
    is_multi_select: bool,
    assessment_repo: &AssessmentRepository,
    submission_repo: &AssessmentRepository,
) -> AppResult<(bool, f64, Vec<(Uuid, bool)>)> {
    let choices = assessment_repo
        .find_choices_by_question_id(question_id)
        .await?;
    let selected = assessment_repo
        .find_answer_choices(submission_answer_id)
        .await?;

    let correct_ids: std::collections::HashSet<Uuid> = choices
        .iter()
        .filter(|c| c.is_correct)
        .map(|c| c.id)
        .collect();

    let selected_ids: std::collections::HashSet<Uuid> = selected.iter().cloned().collect();

    // Per-choice correctness: a selected choice is correct if it is in the correct set
    let per_choice: Vec<(Uuid, bool)> = selected
        .iter()
        .map(|&cid| (cid, correct_ids.contains(&cid)))
        .collect();

    // Persist per-choice correctness to submission_answer_items (like enumeration grader does)
    let items = submission_repo
        .find_answer_items_by_submission_answer_id(submission_answer_id)
        .await?;
    for item in &items {
        if let Some(choice_id) = item.choice_id {
            let is_correct = correct_ids.contains(&choice_id);
            submission_repo
                .update_answer_item_correctness(item.id, is_correct)
                .await?;
        }
    }

    if is_multi_select {
        let correct_selected = selected_ids.intersection(&correct_ids).count();
        let total_correct = correct_ids.len();
        let awarded = if total_correct > 0 {
            (correct_selected as f64 / total_correct as f64) * points as f64
        } else {
            0.0
        };
        let is_any_correct = correct_selected > 0;
        Ok((is_any_correct, awarded, per_choice))
    } else {
        let is_correct = selected_ids.len() == 1 && correct_ids == selected_ids;
        let awarded = if is_correct { points as f64 } else { 0.0 };
        Ok((is_correct, awarded, per_choice))
    }
}
