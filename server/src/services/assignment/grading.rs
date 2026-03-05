use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assignment_schema::*;

impl super::AssignmentService {
    pub async fn get_submissions(
        &self,
        assignment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<SubmissionListResponse> {
        let assignment = self
            .assignment_repo
            .find_by_id(assignment_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        let class = self
            .class_repo
            .find_by_id(assignment.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assignment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let submissions = self
            .assignment_repo
            .find_submissions_by_assignment(assignment_id)
            .await?;

        let items: Vec<SubmissionListItem> = submissions
            .into_iter()
            .map(|(s, user)| SubmissionListItem {
                id: s.id,
                student_id: s.student_id,
                student_name: user.map(|u| u.full_name).unwrap_or_default(),
                status: s.status,
                submitted_at: s.submitted_at.map(|dt| dt.to_string()),
                is_late: s.is_late,
                score: s.score,
            })
            .collect();

        Ok(SubmissionListResponse { submissions: items })
    }

    pub async fn grade_submission(
        &self,
        submission_id: Uuid,
        request: GradeSubmissionRequest,
        teacher_id: Uuid,
    ) -> AppResult<AssignmentSubmissionResponse> {
        let submission = self
            .assignment_repo
            .find_submission_by_id(submission_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        let assignment = self
            .assignment_repo
            .find_by_id(submission.assignment_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        let class = self
            .class_repo
            .find_by_id(assignment.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assignment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if submission.status != "submitted" && submission.status != "returned" && submission.status != "graded" {
            return Err(AppError::BadRequest(format!(
                "Cannot grade a submission with status '{}'",
                submission.status
            )));
        }

        if request.score < 0 || request.score > assignment.total_points {
            return Err(AppError::BadRequest(format!(
                "Score must be between 0 and {}",
                assignment.total_points
            )));
        }

        if let Some(ref feedback) = request.feedback {
            if feedback.len() > 5000 {
                return Err(AppError::BadRequest(
                    "Feedback must be at most 5000 characters".to_string(),
                ));
            }
        }

        let graded = self
            .assignment_repo
            .grade_submission(submission_id, request.score, request.feedback)
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "assignment_graded",
                Some(teacher_id),
                Some(format!(
                    "Graded assignment '{}' - score: {}/{}",
                    assignment.title, request.score, assignment.total_points
                )),
            )
            .await;

        let _ = self.change_log_repo.log_change(
            "assignment_submission",
            submission_id,
            "update",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "status": "graded",
                "score": request.score,
            })).unwrap_or_default()),
        ).await;

        let student_name = self
            .assignment_repo
            .find_student_name(graded.student_id)
            .await?;
        let files = self
            .assignment_repo
            .find_files_by_submission(submission_id)
            .await?;

        Ok(self.build_submission_response(graded, student_name, files))
    }

    pub async fn return_submission(
        &self,
        submission_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<AssignmentSubmissionResponse> {
        let submission = self
            .assignment_repo
            .find_submission_by_id(submission_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        let assignment = self
            .assignment_repo
            .find_by_id(submission.assignment_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        let class = self
            .class_repo
            .find_by_id(assignment.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assignment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if submission.status != "submitted" {
            return Err(AppError::BadRequest(
                "Can only return submitted submissions".to_string(),
            ));
        }

        let returned = self
            .assignment_repo
            .return_submission(submission_id)
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "assignment_returned",
                Some(teacher_id),
                Some(format!(
                    "Returned assignment '{}' for revision",
                    assignment.title
                )),
            )
            .await;

        let _ = self.change_log_repo.log_change(
            "assignment_submission",
            submission_id,
            "update",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "status": "returned",
            })).unwrap_or_default()),
        ).await;

        let student_name = self
            .assignment_repo
            .find_student_name(returned.student_id)
            .await?;
        let files = self
            .assignment_repo
            .find_files_by_submission(submission_id)
            .await?;

        Ok(self.build_submission_response(returned, student_name, files))
    }
}