use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assignment_schema::*;

impl crate::services::assignment::AssignmentService {
    pub async fn get_submission_detail(
        &self,
        submission_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<AssignmentSubmissionResponse> {
        let submission = self.assignment_repo.find_submission_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        let assignment = self.assignment_repo.find_by_id(submission.assignment_id).await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        if role == "teacher" {
            if !self.class_repo.is_teacher_of_class(user_id, assignment.class_id).await? {
                return Err(AppError::Forbidden("Access denied".to_string()));
            }
        } else if submission.student_id != user_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let student_name = self.assignment_repo.find_student_name(submission.student_id).await?;
        let files = self.assignment_repo.find_files_by_submission(submission_id).await?;

        Ok(self.build_submission_response(submission, student_name, files))
    }
}
