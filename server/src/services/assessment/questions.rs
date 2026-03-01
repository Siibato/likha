use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assessment_schema::*;

impl super::AssessmentService {
    pub async fn add_questions(
        &self,
        assessment_id: Uuid,
        request: AddQuestionsRequest,
        teacher_id: Uuid,
    ) -> AppResult<Vec<QuestionResponse>> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if assessment.is_published {
            return Err(AppError::BadRequest("Cannot add questions to a published assessment".to_string()));
        }

        let mut responses = Vec::new();

        for q_request in request.questions {
            let valid_types = ["multiple_choice", "identification", "enumeration"];
            if !valid_types.contains(&q_request.question_type.as_str()) {
                return Err(AppError::BadRequest(format!(
                    "Invalid question type: {}. Must be one of: {:?}",
                    q_request.question_type, valid_types
                )));
            }

            let question = self.assessment_repo.add_question(
                assessment_id,
                q_request.question_type.clone(),
                q_request.question_text.clone(),
                q_request.points,
                q_request.order_index,
                q_request.is_multi_select.unwrap_or(false),
            ).await?;

            let _ = self.change_log_repo.log_change(
                "question",
                question.id,
                "create",
                teacher_id,
                Some(serde_json::to_string(&serde_json::json!({
                    "question_type": q_request.question_type,
                    "points": q_request.points,
                })).unwrap_or_default()),
            ).await;

            self.add_question_type_data(&question, &q_request).await?;

            let response = self.build_question_response(&question, "teacher").await?;
            responses.push(response);
        }

        self.assessment_repo.update_total_points(assessment_id).await?;

        Ok(responses)
    }

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

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
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

        // Update type-specific data if provided
        if let Some(choices) = request.choices {
            self.assessment_repo.delete_choices_by_question_id(question_id).await?;
            for choice in choices {
                self.assessment_repo.add_choice(
                    question_id,
                    choice.choice_text,
                    choice.is_correct,
                    choice.order_index,
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
            self.assessment_repo.delete_enumeration_items_by_question_id(question_id).await?;
            for item_input in items {
                let item = self.assessment_repo
                    .add_enumeration_item(question_id, item_input.order_index)
                    .await?;
                for answer in item_input.acceptable_answers {
                    self.assessment_repo
                        .add_enumeration_item_answer(item.id, answer)
                        .await?;
                }
            }
        }

        self.assessment_repo.update_total_points(question.assessment_id).await?;

        let _ = self.change_log_repo.log_change(
            "question",
            question_id,
            "update",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "points": updated.points,
            })).unwrap_or_default()),
        ).await;

        let response = self.build_question_response(&updated, "teacher").await?;
        Ok(response)
    }

    pub async fn delete_question(
        &self,
        question_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        let question = self.assessment_repo.find_question_by_id(question_id).await?
            .ok_or_else(|| AppError::NotFound("Question not found".to_string()))?;

        let assessment = self.assessment_repo.find_by_id(question.assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if assessment.is_published {
            return Err(AppError::BadRequest("Cannot delete questions from a published assessment".to_string()));
        }

        self.assessment_repo.delete_question(question_id).await?;
        self.assessment_repo.update_total_points(question.assessment_id).await?;

        let _ = self.change_log_repo.log_change(
            "question",
            question_id,
            "delete",
            teacher_id,
            None,
        ).await;

        Ok(())
    }

    async fn add_question_type_data(
        &self,
        question: &entity::assessment_questions::Model,
        request: &AddQuestionRequest,
    ) -> AppResult<()> {
        match request.question_type.as_str() {
            "multiple_choice" => {
                if let Some(choices) = &request.choices {
                    for choice in choices {
                        self.assessment_repo.add_choice(
                            question.id,
                            choice.choice_text.clone(),
                            choice.is_correct,
                            choice.order_index,
                        ).await?;
                    }
                }
            }
            "identification" => {
                if let Some(answers) = &request.correct_answers {
                    for answer in answers {
                        self.assessment_repo.add_correct_answer(question.id, answer.clone()).await?;
                    }
                }
            }
            "enumeration" => {
                if let Some(items) = &request.enumeration_items {
                    for item_input in items {
                        let item = self.assessment_repo
                            .add_enumeration_item(question.id, item_input.order_index)
                            .await?;
                        for answer in &item_input.acceptable_answers {
                            self.assessment_repo
                                .add_enumeration_item_answer(item.id, answer.clone())
                                .await?;
                        }
                    }
                }
            }
            _ => {}
        }
        Ok(())
    }
}