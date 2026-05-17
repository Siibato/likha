use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};

impl crate::services::assignment::AssignmentService {
    pub async fn delete_assignment(
        &self,
        assignment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        let assignment = self.assignment_repo.find_by_id(assignment_id).await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assignment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assignment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        self.assignment_repo.soft_delete(assignment_id).await?;

        let _ = self.activity_log_repo.create_log(
            teacher_id,
            "assignment_deleted",
            Some(format!("Assignment '{}' deleted", assignment.title)),
        ).await;

        Ok(())
    }
}
