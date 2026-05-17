use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assignment_schema::*;

impl crate::services::assignment::AssignmentService {
    pub async fn get_assignments(
        &self,
        class_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<AssignmentListResponse> {
        let _ = self.class_repo.find_by_id(class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        let is_teacher_of_class = role == "teacher" && self.class_repo.is_teacher_of_class(user_id, class_id).await?;
        let assignments = if is_teacher_of_class {
            self.assignment_repo.find_by_class_id(class_id).await?
        } else {
            self.assignment_repo.find_published_by_class_id(class_id).await?
        };

        let mut responses = Vec::new();
        for a in assignments {
            let submission_count = self.assignment_repo.count_submissions_by_assignment(a.id).await?;
            let graded_count = self.assignment_repo.count_graded_by_assignment(a.id).await?;

            let (submission_status, submission_id, score) = if role == "student" {
                let submission = self.assignment_repo.find_student_submission(a.id, user_id).await?;
                (
                    submission.as_ref().map(|s| s.status.clone()),
                    submission.as_ref().map(|s| s.id),
                    submission.and_then(|s| s.points),
                )
            } else {
                (None, None, None)
            };

            responses.push(AssignmentResponse {
                id: a.id,
                class_id: a.class_id,
                title: a.title,
                instructions: a.instructions,
                total_points: a.total_points,
                allows_text_submission: a.allows_text_submission,
                allows_file_submission: a.allows_file_submission,
                allowed_file_types: a.allowed_file_types,
                max_file_size_mb: a.max_file_size_mb,
                due_at: a.due_at.to_string(),
                is_published: a.is_published,
                order_index: a.order_index,
                submission_count,
                graded_count,
                grading_period_number: a.grading_period_number,
                component: a.component.clone(),
                submission_status,
                submission_id,
                score,
                created_at: a.created_at.to_string(),
                updated_at: a.updated_at.to_string(),
            });
        }

        Ok(AssignmentListResponse { assignments: responses })
    }
}
