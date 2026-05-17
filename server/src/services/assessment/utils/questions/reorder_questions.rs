use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assessment_schema::*;

impl crate::services::assessment::AssessmentService {
    pub async fn reorder_questions(
        &self,
        assessment_id: Uuid,
        request: ReorderQuestionsRequest,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Teacher access required".to_string()));
        }

        if assessment.is_published {
            return Err(AppError::BadRequest("Cannot reorder questions of a published assessment".to_string()));
        }

        if request.question_ids.is_empty() {
            return Ok(());
        }

        self.assessment_repo.reorder_questions(assessment_id, request.question_ids).await?;
        Ok(())
    }
}
