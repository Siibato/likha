use uuid::Uuid;
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
    let enum_items = assessment_repo
        .find_enumeration_items_by_question_id(question_id)
        .await?;

    if enum_items.is_empty() {
        return Ok((false, 0.0));
    }

    let student_enum_answers = submission_repo
        .find_enumeration_answers(submission_answer_id)
        .await?;

    let mut item_answers: Vec<(Uuid, Vec<String>)> = Vec::new();
    for item in &enum_items {
        let answers = assessment_repo.find_enumeration_item_answers(item.id).await?;
        let texts: Vec<String> = answers.iter().map(|a| a.answer_text.clone()).collect();
        item_answers.push((item.id, texts));
    }

    let mut matched_items: std::collections::HashSet<Uuid> = std::collections::HashSet::new();
    let mut matched_count = 0;

    for student_answer in &student_enum_answers {
        let normalized = student_answer.answer_text.trim().to_lowercase();
        let mut found_match = false;

        for (item_id, acceptable) in &item_answers {
            if matched_items.contains(item_id) {
                continue;
            }
            if acceptable.iter().any(|a| *a == normalized) {
                matched_items.insert(*item_id);
                matched_count += 1;
                found_match = true;

                submission_repo
                    .update_enumeration_answer_grade(student_answer.id, Some(*item_id), true)
                    .await?;
                break;
            }
        }

        if !found_match {
            submission_repo
                .update_enumeration_answer_grade(student_answer.id, None, false)
                .await?;
        }
    }

    let total_items = enum_items.len() as f64;
    let awarded = (matched_count as f64 / total_items) * points as f64;
    let is_fully_correct = matched_count == enum_items.len();

    Ok((is_fully_correct, awarded))
}