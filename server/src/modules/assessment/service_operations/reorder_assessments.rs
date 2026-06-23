use crate::modules::assessment::schema::*;
use crate::utils::error::{AppError, AppResult};
use uuid::Uuid;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn reorder_assessments(
        &self,
        class_id: Uuid,
        request: ReorderAssessmentsRequest,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        let _class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self
            .class_repo
            .is_teacher_of_class(teacher_id, class_id)
            .await?
        {
            return Err(AppError::Forbidden(
                "You can only reorder assessments in your own classes".to_string(),
            ));
        }

        if request.assessment_ids.is_empty() {
            return Ok(());
        }

        self.assessment_repo
            .reorder_assessments(class_id, request.assessment_ids)
            .await?;

        if let Some(ref inv) = self.invalidator {
            inv.invalidate_assessments(teacher_id, class_id).await;
        }

        Ok(())
    }
}
