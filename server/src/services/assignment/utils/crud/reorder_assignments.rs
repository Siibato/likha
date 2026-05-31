use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assignment_schema::*;

impl crate::services::assignment::AssignmentService {
    pub async fn reorder_assignments(
        &self,
        class_id: Uuid,
        request: ReorderAssignmentsRequest,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        let _class = self.class_repo.find_by_id(class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden(
                "You can only reorder assignments in your own classes".to_string(),
            ));
        }

        if request.assignment_ids.is_empty() {
            return Ok(());
        }

        self.assignment_repo.reorder_assignments(class_id, request.assignment_ids).await?;

        Ok(())
    }
}
