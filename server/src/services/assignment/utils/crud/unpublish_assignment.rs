use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assignment_schema::*;

impl crate::services::assignment::AssignmentService {
    pub async fn unpublish_assignment(
        &self,
        assignment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<AssignmentResponse> {
        let assignment = self.assignment_repo.find_by_id(assignment_id).await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assignment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assignment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if !assignment.is_published {
            return Err(AppError::BadRequest("Assignment is not published".to_string()));
        }

        let unpublished = self.assignment_repo.unpublish_assignment(assignment_id).await?;

        let _ = self.activity_log_repo.create_log(
            teacher_id,
            "assignment_unpublished",
            Some(format!("Assignment '{}' unpublished", unpublished.title)),
        ).await;

        Ok(AssignmentResponse {
            id: unpublished.id,
            class_id: unpublished.class_id,
            title: unpublished.title,
            instructions: unpublished.instructions,
            total_points: unpublished.total_points,
            allows_text_submission: unpublished.allows_text_submission,
            allows_file_submission: unpublished.allows_file_submission,
            allowed_file_types: unpublished.allowed_file_types,
            max_file_size_mb: unpublished.max_file_size_mb,
            due_at: unpublished.due_at.to_string(),
            is_published: unpublished.is_published,
            order_index: unpublished.order_index,
            submission_count: 0,
            graded_count: 0,
            grading_period_number: unpublished.grading_period_number,
            component: unpublished.component.clone(),
            submission_status: None,
            submission_id: None,
            score: None,
            created_at: unpublished.created_at.to_string(),
            updated_at: unpublished.updated_at.to_string(),
        })
    }
}
