use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assignment_schema::*;

impl crate::services::assignment::AssignmentService {
    pub async fn create_or_get_submission(
        &self,
        assignment_id: Uuid,
        student_id: Uuid,
        text_content: Option<String>,
        submission_id: Option<Uuid>,
    ) -> AppResult<AssignmentSubmissionResponse> {
        let assignment = self.assignment_repo.find_by_id(assignment_id).await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        if !assignment.is_published {
            return Err(AppError::NotFound("Assignment not found".to_string()));
        }

        let enrolled = self.class_repo.is_student_enrolled(assignment.class_id, student_id).await?;
        if !enrolled {
            return Err(AppError::Forbidden("You are not enrolled in this class".to_string()));
        }

        if let Some(ref text) = text_content {
            if !text.is_empty() && !assignment.allows_text_submission {
                return Err(AppError::BadRequest(
                    "This assignment does not accept text submissions".to_string(),
                ));
            }
            if text.len() > 200000 {
                return Err(AppError::BadRequest(
                    "Text content must be at most 200000 characters".to_string(),
                ));
            }
        }

        let submission = match self.assignment_repo.find_student_submission(assignment_id, student_id).await? {
            Some(existing) => {
                if existing.status == "graded" {
                    return Err(AppError::BadRequest("This submission has already been graded".to_string()));
                }
                if existing.status == "submitted" {
                    let now = chrono::Utc::now().naive_utc();
                    if now > assignment.due_at {
                        return Err(AppError::BadRequest(
                            "The deadline has passed. You can no longer edit this submission.".to_string(),
                        ));
                    }
                }
                if text_content.is_some() {
                    self.assignment_repo.update_submission_text(existing.id, text_content).await?
                } else {
                    existing
                }
            }
            None => {
                let sub = self.assignment_repo.create_submission(assignment_id, student_id, submission_id).await?;
                if text_content.is_some() {
                    self.assignment_repo.update_submission_text(sub.id, text_content).await?
                } else {
                    sub
                }
            }
        };

        let student_name = self.assignment_repo.find_student_name(student_id).await?;
        let files = self.assignment_repo.find_files_by_submission(submission.id).await?;

        Ok(self.build_submission_response(submission, student_name, files))
    }
}
