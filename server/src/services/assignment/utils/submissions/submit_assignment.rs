use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assignment_schema::*;

impl crate::services::assignment::AssignmentService {
    pub async fn submit_assignment(
        &self,
        submission_id: Uuid,
        student_id: Uuid,
        text_content: Option<String>,
    ) -> AppResult<AssignmentSubmissionResponse> {
        let submission = self.assignment_repo.find_submission_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        if submission.student_id != student_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let assignment = self.assignment_repo.find_by_id(submission.assignment_id).await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        if submission.status != "draft" && submission.status != "returned" && submission.status != "submitted" {
            return Err(AppError::BadRequest(format!(
                "Cannot submit a submission with status '{}'", submission.status
            )));
        }

        if submission.status == "submitted" {
            let now = chrono::Utc::now().naive_utc();
            if now > assignment.due_at {
                return Err(AppError::BadRequest(
                    "The deadline has passed. You can no longer resubmit.".to_string(),
                ));
            }
        }

        if text_content.is_some() {
            self.assignment_repo.update_submission_text(submission_id, text_content).await?;
        }

        let updated = self.assignment_repo.update_submission_status(submission_id, "submitted").await?;

        let _ = self.activity_log_repo.create_log(
            student_id,
            "assignment_submitted",
            Some(format!("Submitted assignment '{}'", assignment.title)),
        ).await;

        let student_name = self.assignment_repo.find_student_name(student_id).await?;
        let files = self.assignment_repo.find_files_by_submission(submission_id).await?;

        Ok(self.build_submission_response(updated, student_name, files))
    }
}
