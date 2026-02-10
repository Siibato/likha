use uuid::Uuid;

use crate::db::repositories::assessment_repository::AssessmentRepository;
use crate::db::repositories::submission_repository::SubmissionRepository;
use crate::utils::AppResult;

pub struct GradingService;

impl GradingService {
    pub async fn grade_submission(
        submission_id: Uuid,
        assessment_repo: &AssessmentRepository,
        submission_repo: &SubmissionRepository,
    ) -> AppResult<(f64, f64)> {
        let answers = submission_repo.find_answers_by_submission_id(submission_id).await?;
        let mut auto_score = 0.0_f64;

        for answer in &answers {
            let question = assessment_repo
                .find_question_by_id(answer.question_id)
                .await?;

            let question = match question {
                Some(q) => q,
                None => continue,
            };

            let (is_correct, points_awarded) = match question.question_type.as_str() {
                "multiple_choice" => {
                    Self::grade_multiple_choice(
                        answer.id,
                        question.id,
                        question.points,
                        question.is_multi_select,
                        assessment_repo,
                        submission_repo,
                    )
                    .await?
                }
                "identification" => {
                    Self::grade_identification(
                        &answer.answer_text,
                        question.id,
                        question.points,
                        assessment_repo,
                    )
                    .await?
                }
                "enumeration" => {
                    Self::grade_enumeration(
                        answer.id,
                        question.id,
                        question.points,
                        assessment_repo,
                        submission_repo,
                    )
                    .await?
                }
                _ => (false, 0.0),
            };

            submission_repo
                .update_answer_grade(answer.id, Some(is_correct), points_awarded)
                .await?;

            auto_score += points_awarded;
        }

        submission_repo
            .update_submission_scores(submission_id, auto_score, auto_score)
            .await?;

        Ok((auto_score, auto_score))
    }

    async fn grade_multiple_choice(
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
            selected.iter().map(|s| s.choice_id).collect();

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

    async fn grade_identification(
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

    async fn grade_enumeration(
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

        // Build mapping of item_id -> acceptable answers
        let mut item_answers: Vec<(Uuid, Vec<String>)> = Vec::new();
        for item in &enum_items {
            let answers = assessment_repo.find_enumeration_item_answers(item.id).await?;
            let texts: Vec<String> = answers.iter().map(|a| a.answer_text.clone()).collect();
            item_answers.push((item.id, texts));
        }

        // Greedy matching
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

    pub async fn recalculate_final_score(
        submission_id: Uuid,
        submission_repo: &SubmissionRepository,
    ) -> AppResult<f64> {
        let answers = submission_repo.find_answers_by_submission_id(submission_id).await?;
        let final_score: f64 = answers.iter().map(|a| a.points_awarded).sum();
        // Auto score stays the same as original
        let submission = submission_repo.find_by_id(submission_id).await?;
        let auto = submission.map(|s| s.auto_score).unwrap_or(0.0);

        submission_repo
            .update_submission_scores(submission_id, auto, final_score)
            .await?;

        Ok(final_score)
    }
}
