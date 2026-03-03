use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assessment_schema::*;

impl super::AssessmentService {
    pub async fn get_student_results(
        &self,
        submission_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<StudentResultResponse> {
        let submission = self.submission_repo.find_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        if submission.student_id != student_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if !submission.is_submitted {
            return Err(AppError::BadRequest("Assessment not yet submitted".to_string()));
        }

        let assessment = self.assessment_repo.find_by_id(submission.assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        if !assessment.show_results_immediately && !assessment.results_released {
            return Err(AppError::Forbidden("Results have not been released yet".to_string()));
        }

        let answers = self.submission_repo
            .find_answers_by_submission_id(submission_id).await?;

        let mut answer_results = Vec::new();
        for a in answers {
            let question = self.assessment_repo.find_question_by_id(a.question_id).await?;
            let question = match question {
                Some(q) => q,
                None => continue,
            };

            let is_correct = a.is_override_correct.or(a.is_auto_correct);

            let selected_choices = if question.question_type == "multiple_choice" {
                let selections = self.submission_repo.find_answer_choices(a.id).await?;
                let choices = self.assessment_repo.find_choices_by_question_id(question.id).await?;
                let texts: Vec<String> = selections.iter().filter_map(|s| {
                    choices.iter().find(|c| c.id == s.choice_id).map(|c| c.choice_text.clone())
                }).collect();
                Some(texts)
            } else {
                None
            };

            let enumeration_answers = if question.question_type == "enumeration" {
                let enum_ans = self.submission_repo.find_enumeration_answers(a.id).await?;
                Some(enum_ans.into_iter().map(|ea| {
                    let is_correct = ea.is_override_correct.or(ea.is_auto_correct);
                    StudentEnumAnswerResult {
                        answer_text: ea.answer_text,
                        is_correct,
                    }
                }).collect())
            } else {
                None
            };

            let correct_answers = match question.question_type.as_str() {
                "multiple_choice" => {
                    let choices = self.assessment_repo.find_choices_by_question_id(question.id).await?;
                    Some(choices.iter().filter(|c| c.is_correct).map(|c| c.choice_text.clone()).collect())
                }
                "identification" => {
                    let answers = self.assessment_repo.find_correct_answers_by_question_id(question.id).await?;
                    Some(answers.iter().map(|a| a.answer_text.clone()).collect())
                }
                "enumeration" => {
                    let items = self.assessment_repo.find_enumeration_items_by_question_id(question.id).await?;
                    let mut all_answers = Vec::new();
                    for item in items {
                        let item_answers = self.assessment_repo.find_enumeration_item_answers(item.id).await?;
                        if let Some(first) = item_answers.first() {
                            all_answers.push(first.answer_text.clone());
                        }
                    }
                    Some(all_answers)
                }
                _ => None,
            };

            answer_results.push(StudentAnswerResultResponse {
                question_id: question.id,
                question_text: question.question_text,
                question_type: question.question_type,
                points: question.points,
                points_awarded: a.points_awarded,
                is_correct,
                answer_text: a.answer_text,
                selected_choices,
                enumeration_answers,
                correct_answers,
            });
        }

        Ok(StudentResultResponse {
            submission_id: submission.id,
            auto_score: submission.auto_score,
            final_score: submission.final_score,
            total_points: assessment.total_points,
            submitted_at: submission.submitted_at.map(|dt| dt.to_string()),
            answers: answer_results,
        })
    }
}