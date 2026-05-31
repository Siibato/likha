use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assignment_schema::*;
use crate::services::grade_computation::auto_populate;

impl crate::services::assignment::AssignmentService {
    pub async fn publish_assignment(
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

        if assignment.is_published {
            return Err(AppError::BadRequest("Assignment is already published".to_string()));
        }

        let published = self.assignment_repo.publish_assignment(assignment_id).await?;

        if let (Some(grading_period_number), Some(ref component)) = (published.grading_period_number, &published.component) {
            let _ = auto_populate::create_linked_grade_item(
                &self.grade_computation_repo, "assignment", published.id, published.class_id,
                &published.title, component, grading_period_number,
                published.total_points as f64,
            ).await;
        }

        let _ = self.activity_log_repo.create_log(
            teacher_id,
            "assignment_published",
            Some(format!("Assignment '{}' published", published.title)),
        ).await;

        Ok(AssignmentResponse {
            id: published.id,
            class_id: published.class_id,
            title: published.title,
            instructions: published.instructions,
            total_points: published.total_points,
            allows_text_submission: published.allows_text_submission,
            allows_file_submission: published.allows_file_submission,
            allowed_file_types: published.allowed_file_types,
            max_file_size_mb: published.max_file_size_mb,
            due_at: published.due_at.to_string(),
            is_published: published.is_published,
            order_index: published.order_index,
            submission_count: 0,
            graded_count: 0,
            grading_period_number: published.grading_period_number,
            component: published.component.clone(),
            submission_status: None,
            submission_id: None,
            score: None,
            created_at: published.created_at.to_string(),
            updated_at: published.updated_at.to_string(),
        })
    }
}
