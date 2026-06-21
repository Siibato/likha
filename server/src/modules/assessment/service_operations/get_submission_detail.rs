use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::assessment::schema::*;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn get_submission_detail(
        &self,
        submission_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<SubmissionDetailResponse> {
        let submission = self.assessment_repo.find_submission_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        let assessment = self.assessment_repo.find_by_id(submission.assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let student = self.user_repo.find_by_id(submission.user_id).await?
            .ok_or_else(|| AppError::NotFound("Student not found".to_string()))?;

        let answers = self.assessment_repo
            .find_answers_by_submission_id(submission_id).await?;

        let mut answer_responses = Vec::new();
        for a in answers {
            let question = self.assessment_repo.find_question_by_id(a.question_id).await?;
            let question = match question {
                Some(q) => q,
                None => continue,
            };

            let selected_choices = if question.question_type == "multiple_choice" {
                let selection_ids = self.assessment_repo.find_answer_choices(a.id).await?;
                let mut choice_responses = Vec::new();
                let choices = self.assessment_repo.find_choices_by_question_id(question.id).await?;
                for choice_id in selection_ids {
                    if let Some(choice) = choices.iter().find(|c| c.id == choice_id) {
                        choice_responses.push(SelectedChoiceResponse {
                            choice_id: choice.id,
                            choice_text: choice.choice_text.clone(),
                            is_correct: choice.is_correct,
                        });
                    }
                }
                Some(choice_responses)
            } else {
                None
            };

            let enumeration_answers = if question.question_type == "enumeration" {
                let enum_items = self.assessment_repo.find_enumeration_answer_items(a.id).await?;
                Some(
                    enum_items.into_iter().map(|item| EnumerationAnswerResponse {
                        answer_text: item.answer_text.unwrap_or_default(),
                        is_correct: item.is_correct,
                    }).collect()
                )
            } else {
                None
            };

            let answer_text = if question.question_type == "identification" || question.question_type == "essay" {
                let texts = self.assessment_repo.find_enumeration_answers(a.id).await?;
                texts.into_iter().next()
            } else {
                None
            };

            let is_pending_essay_grade = question.question_type == "essay" && a.overridden_at.is_none();

            answer_responses.push(SubmissionAnswerResponse {
                id: a.id,
                question_id: a.question_id,
                question_text: question.question_text,
                question_type: question.question_type,
                question_points: question.points,
                answer_text,
                selected_choices,
                enumeration_answers,
                points_earned: a.points,
                overridden_by: a.overridden_by,
                overridden_at: a.overridden_at.map(|dt| dt.to_string()),
                is_pending_essay_grade,
            });
        }

        let earned_score: f64 = answer_responses.iter().map(|a| a.points_earned).sum::<f64>();

        Ok(SubmissionDetailResponse {
            id: submission.id,
            assessment_id: submission.assessment_id,
            student_id: submission.user_id,
            student_first_name: student.first_name,
            student_last_name: student.last_name,
            started_at: submission.started_at.to_string(),
            submitted_at: submission.submitted_at.map(|dt| dt.to_string()),
            total_points: submission.total_points,
            auto_score: earned_score,
            final_score: earned_score,
            answers: answer_responses,
        })
    }
}
