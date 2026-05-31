use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};

impl crate::services::assessment::AssessmentService {
    pub async fn soft_delete(
        &self,
        assessment_id: Uuid,
        user_id: Uuid,
        user_role: &str,
    ) -> AppResult<()> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if user_role != "admin" && !self.class_repo.is_teacher_of_class(user_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        self.assessment_repo.soft_delete(assessment_id).await?;

        Ok(())
    }
}
