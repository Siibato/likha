use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::assessment::schema::*;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn update_question(
        &self,
        question_id: Uuid,
        request: UpdateQuestionRequest,
        teacher_id: Uuid,
    ) -> AppResult<QuestionResponse> {
        let question = self.assessment_repo.find_question_by_id(question_id).await?
            .ok_or_else(|| AppError::NotFound("Question not found".to_string()))?;

        let assessment = self.assessment_repo.find_by_id(question.assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if assessment.is_published {
            return Err(AppError::BadRequest("Cannot edit questions in a published assessment".to_string()));
        }

        let updated = self.assessment_repo.update_question(
            question_id,
            request.question_text,
            request.points,
            request.order_index,
            request.is_multi_select,
        ).await?;

        if let Some(choices) = request.choices {
            self.assessment_repo.delete_choices_by_question_id(question_id).await?;
            for choice in choices {
                self.assessment_repo.add_choice(
                    question_id,
                    choice.choice_text,
                    choice.is_correct,
                    choice.order_index,
                    None,
                ).await?;
            }
        }

        if let Some(answers) = request.correct_answers {
            self.assessment_repo.delete_correct_answers_by_question_id(question_id).await?;
            for answer in answers {
                self.assessment_repo.add_correct_answer(question_id, answer).await?;
            }
        }

        if let Some(items) = request.enumeration_items {
            self.assessment_repo.delete_all_answer_keys_for_question(question_id).await?;
            for item in items {
                self.assessment_repo
                    .add_enumeration_item(question_id, item.acceptable_answers)
                    .await?;
            }
        }

        self.assessment_repo.update_total_points(question.assessment_id).await?;

        let response = self.build_question_response(&updated, "teacher").await?;
        Ok(response)
    }
}
