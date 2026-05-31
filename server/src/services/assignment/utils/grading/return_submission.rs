use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assignment_schema::*;

impl crate::services::assignment::AssignmentService {
    pub async fn return_submission(
        &self,
        submission_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<AssignmentSubmissionResponse> {
        let submission = self.assignment_repo.find_submission_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        let assignment = self.assignment_repo.find_by_id(submission.assignment_id).await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assignment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assignment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if submission.status != "submitted" {
            return Err(AppError::BadRequest(
                "Can only return submitted submissions".to_string(),
            ));
        }

        let returned = self.assignment_repo.return_submission(submission_id).await?;

        let _ = self.activity_log_repo.create_log(
            teacher_id,
            "assignment_returned",
            Some(format!("Returned assignment '{}' for revision", assignment.title)),
        ).await;

        let student_name = self.assignment_repo.find_student_name(returned.student_id).await?;
        let files = self.assignment_repo.find_files_by_submission(submission_id).await?;

        Ok(self.build_submission_response(returned, student_name, files))
    }
}
