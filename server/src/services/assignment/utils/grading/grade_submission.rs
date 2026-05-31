use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assignment_schema::*;
use crate::services::grade_computation::auto_populate;

impl crate::services::assignment::AssignmentService {
    pub async fn grade_submission(
        &self,
        submission_id: Uuid,
        request: GradeSubmissionRequest,
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

        let graded = self.assignment_repo.grade_submission(
            submission_id, request.score, request.feedback, Some(teacher_id),
        ).await?;

        let _ = auto_populate::auto_populate_score(
            &self.grade_computation_repo, "assignment", submission.assignment_id, submission.student_id, request.score as f64,
        ).await;

        let _ = self.activity_log_repo.create_log(
            teacher_id,
            "assignment_graded",
            Some(format!(
                "Graded assignment '{}' - score: {}/{}",
                assignment.title, request.score, assignment.total_points
            )),
        ).await;

        let student_name = self.assignment_repo.find_student_name(graded.student_id).await?;
        let files = self.assignment_repo.find_files_by_submission(submission_id).await?;

        Ok(self.build_submission_response(graded, student_name, files))
    }
}
