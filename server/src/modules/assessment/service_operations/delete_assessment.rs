use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};

impl crate::modules::assessment::service::AssessmentService {
    pub async fn delete_assessment(
        &self,
        assessment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        self.assessment_repo.soft_delete_submissions_by_assessment(assessment_id).await?;
        self.assessment_repo.soft_delete(assessment_id).await?;

        Ok(())
    }
}
