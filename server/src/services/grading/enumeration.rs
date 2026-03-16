use uuid::Uuid;
use std::collections::HashSet;
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

    // Fetch student's answer items
    let items = submission_repo.find_answer_items_by_submission_answer_id(submission_answer_id).await?;

    // Build a mutable pool of available student answers (id, normalized_text)
    // Skip blank answers as they cannot match
    let mut available: Vec<(Uuid, String)> = items.iter()
        .filter_map(|item| {
            let text = item.answer_text.as_deref()
                .map(|t| t.trim().to_lowercase())
                .filter(|t| !t.is_empty())?;
            Some((item.id, text))
        })
        .collect();

    let total = slots.len();
    let mut correct_count = 0usize;
    let mut correct_item_ids: HashSet<Uuid> = HashSet::new();

    // Greedy set-matching: for each slot, find the first unmatched student answer that fits
    for (_key, acceptable_answers) in &slots {
        // Normalize acceptable answers for this slot
        let normalized_acceptable: HashSet<String> = acceptable_answers.iter()
            .map(|a| a.answer_text.trim().to_lowercase())
            .collect();

        // Find and consume the first student answer that matches any acceptable answer
        if let Some(pos) = available.iter().position(|(_, text)| normalized_acceptable.contains(text)) {
            let (item_id, _) = available.remove(pos);
            correct_item_ids.insert(item_id);
            correct_count += 1;
        }
    }

    // Update per-item correctness for all items (matched items are correct, unmatched are incorrect)
    for item in &items {
        let is_correct = correct_item_ids.contains(&item.id);
        submission_repo
            .update_answer_item_correctness(item.id, is_correct)
            .await?;
    }

    let partial_points = (correct_count as f64 / total as f64) * points as f64;
    Ok((correct_count > 0, partial_points))
}