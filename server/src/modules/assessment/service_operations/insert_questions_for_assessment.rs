use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::assessment::schema::*;

impl crate::modules::assessment::service::AssessmentService {
    pub(crate) async fn insert_questions_for_assessment(
        &self,
        assessment_id: Uuid,
        questions: Vec<AddQuestionRequest>,
        _teacher_id: Uuid,
    ) -> AppResult<Vec<QuestionResponse>> {
        let mut responses = Vec::new();

        for q_request in questions {
            let valid_types = ["multiple_choice", "identification", "enumeration", "essay"];
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
                q_request.id,
            ).await?;

            self.add_question_type_data(&question, &q_request).await?;

            let response = self.build_question_response(&question, "teacher").await?;
            responses.push(response);
        }

        self.assessment_repo.update_total_points(assessment_id).await?;

        Ok(responses)
    }
}
