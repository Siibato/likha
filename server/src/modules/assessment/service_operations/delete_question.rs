use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};

impl crate::modules::assessment::service::AssessmentService {
    pub async fn delete_question(
        &self,
        question_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<()> {
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
            return Err(AppError::BadRequest("Cannot delete questions from a published assessment".to_string()));
        }

        self.assessment_repo.delete_question(question_id).await?;
        self.assessment_repo.update_total_points(question.assessment_id).await?;

        if let Some(ref inv) = self.invalidator {
            inv.invalidate_assessment_detail(question.assessment_id).await;
        }

        Ok(())
    }
}
