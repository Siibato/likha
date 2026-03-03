use uuid::Uuid;
use crate::db::repositories::assessment_repository::AssessmentRepository;
use crate::utils::AppResult;

pub async fn grade_identification(
    answer_text: &Option<String>,
    question_id: Uuid,
    points: i32,
    assessment_repo: &AssessmentRepository,
) -> AppResult<(bool, f64)> {
    let student_answer = match answer_text {
        Some(text) => text.trim().to_lowercase(),
        None => return Ok((false, 0.0)),
    };

    if student_answer.is_empty() {
        return Ok((false, 0.0));
    }

    let correct_answers = assessment_repo
        .find_correct_answers_by_question_id(question_id)
        .await?;

    let is_correct = correct_answers
        .iter()
        .any(|ca| ca.answer_text == student_answer);

    let awarded = if is_correct { points as f64 } else { 0.0 };
    Ok((is_correct, awarded))
}