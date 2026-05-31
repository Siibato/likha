use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assessment_schema::*;

impl crate::services::assessment::AssessmentService {
    pub async fn add_questions(
        &self,
        assessment_id: Uuid,
        request: AddQuestionsRequest,
        teacher_id: Uuid,
    ) -> AppResult<Vec<QuestionResponse>> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if assessment.is_published {
            return Err(AppError::BadRequest("Cannot add questions to a published assessment".to_string()));
        }

        self.insert_questions_for_assessment(assessment_id, request.questions, teacher_id).await
    }
}
