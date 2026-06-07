use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::assessment::schema::*;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn submit_assessment(
        &self,
        submission_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<SubmissionSummaryResponse> {
        println!("📤 [SERVICE] submit_assessment() START - submission_id: {}, student_id: {}", submission_id, student_id);

        let submission = self.assessment_repo.find_submission_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        println!("📤 [SERVICE] submit_assessment() - submission found: submitted_at={:?}, assessment_id={}",
            submission.submitted_at, submission.assessment_id);

        if submission.user_id != student_id {
            println!("📤 [SERVICE] submit_assessment() ERROR - student mismatch: expected {}, got {}", submission.user_id, student_id);
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if submission.submitted_at.is_some() {
            println!("📤 [SERVICE] submit_assessment() ERROR - already submitted at {:?}", submission.submitted_at);
            return Err(AppError::BadRequest("Assessment already submitted".to_string()));
        }

        println!("? [SERVICE] submit_assessment() - grading submission...");
        let (auto_score, final_score) = self.grade_submission(submission_id).await?;
        println!("📤 [SERVICE] submit_assessment() - grading complete: auto_score={}, final_score={}", auto_score, final_score);

        println!("📤 [SERVICE] submit_assessment() - marking as submitted...");
        let submitted = self.assessment_repo.mark_submitted(submission_id).await?;

        println!("📤 [SERVICE] submit_assessment() - mark_submitted() returned: submitted_at={:?}",
            submitted.submitted_at);

        let student = self.user_repo.find_by_id(student_id).await?
            .ok_or_else(|| AppError::NotFound("Student not found".to_string()))?;

        if let Some(ref inv) = self.invalidator {
            inv.invalidate_assessment_submissions(submission.assessment_id).await;
            inv.invalidate_assessment_submission_detail(submission_id).await;
            inv.invalidate_student_results(submission_id).await;
        }

        let response = SubmissionSummaryResponse {
            id: submitted.id,
            student_id: submitted.user_id,
            student_name: student.full_name,
            student_username: student.username,
            started_at: submitted.started_at.to_string(),
            submitted_at: submitted.submitted_at.map(|dt| dt.to_string()),
            total_points: submitted.total_points,
            auto_score,
            final_score,
        };

        Ok(response)
    }
}
