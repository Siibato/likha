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

        if submission.user_id != student_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if submission.submitted_at.is_none() {
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

            let is_correct = Some(a.points > 0.0);

            let selected_choices = if question.question_type == "multiple_choice" {
                let choice_ids = self.submission_repo.find_answer_choices(a.id).await?;
                let choices = self.assessment_repo.find_choices_by_question_id(question.id).await?;
                let texts: Vec<String> = choice_ids.iter().filter_map(|choice_id| {
                    choices.iter().find(|c| c.id == *choice_id).map(|c| c.choice_text.clone())
                }).collect();
                Some(texts)
            } else {
                None
            };

            let enumeration_answers = if question.question_type == "enumeration" {
                let enum_texts = self.submission_repo.find_enumeration_answers(a.id).await?;
                Some(enum_texts.into_iter().map(|answer_text| {
                    StudentEnumAnswerResult {
                        answer_text,
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
                    let answer_keys = self.assessment_repo.find_correct_answers_by_question_id(question.id).await?;
                    Some(answer_keys.iter().map(|a| a.answer_text.clone()).collect())
                }
                "enumeration" => {
                    // New schema: use answer keys for enumeration
                    let answer_keys = self.assessment_repo.find_correct_answers_by_question_id(question.id).await?;
                    Some(answer_keys.iter().map(|a| a.answer_text.clone()).collect())
                }
                _ => None,
            };

            answer_results.push(StudentAnswerResultResponse {
                question_id: question.id,
                question_text: question.question_text,
                question_type: question.question_type,
                points: question.points,
                points_awarded: a.points,
                is_correct,
                answer_text: None, // Answer text is now in submission_answer_items
                selected_choices,
                enumeration_answers,
                correct_answers,
            });
        }

        Ok(StudentResultResponse {
            submission_id: submission.id,
            total_earned: submission.total_points,
            total_possible: assessment.total_points,
            submitted_at: submission.submitted_at.map(|dt| dt.to_string()),
            answers: answer_results,
        })
    }
}