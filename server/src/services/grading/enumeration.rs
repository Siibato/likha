use uuid::Uuid;
use std::collections::HashMap;
use crate::db::repositories::assessment_repository::AssessmentRepository;
use crate::db::repositories::submission_repository::SubmissionRepository;
use crate::utils::AppResult;

pub async fn grade_enumeration(
    submission_answer_id: Uuid,
    question_id: Uuid,
    points: i32,
    assessment_repo: &AssessmentRepository,
    submission_repo: &SubmissionRepository,
) -> AppResult<(bool, f64)> {
    // Fetch the enumeration slots (answer_keys with their acceptable_answers)
    let slots = assessment_repo.find_enumeration_items_for_question(question_id).await?;
    if slots.is_empty() {
        return Ok((false, 0.0));
    }

    // Fetch student's answer items (linked to slots via answer_key_id)
    let items = submission_repo.find_answer_items_by_submission_answer_id(submission_answer_id).await?;

    // Build map: answer_key_id -> item for quick lookup
    let item_map: HashMap<Uuid, &::entity::submission_answer_items::Model> = items.iter()
        .filter_map(|item| item.answer_key_id.map(|k| (k, item)))
        .collect();

    let total = slots.len();
    let mut correct_count = 0usize;

    for (key, acceptable_answers) in &slots {
        if let Some(item) = item_map.get(&key.id) {
            let student_text = item.answer_text.as_deref()
                .map(|t| t.trim().to_lowercase())
                .unwrap_or_default();

            let is_slot_correct = !student_text.is_empty() && acceptable_answers.iter()
                .any(|a| a.answer_text == student_text);

            if is_slot_correct {
                correct_count += 1;
            }

            // Update per-item correctness for teacher UI
            submission_repo
                .update_answer_item_correctness(item.id, is_slot_correct)
                .await?;
        }
        // Items with no answer_key_id (old data) stay at is_correct=false
    }

    let partial_points = (correct_count as f64 / total as f64) * points as f64;
    Ok((correct_count > 0, partial_points))
}