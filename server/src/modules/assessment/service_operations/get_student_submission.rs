use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::assessment::schema::SubmissionSummaryResponse;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn get_student_submission(
        &self,
        assessment_id: Uuid,
        student_id: Uuid,
        user_id: Uuid,
        _role: &str,
    ) -> AppResult<Option<SubmissionSummaryResponse>> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let is_teacher = self.class_repo.is_teacher_of_class(user_id, assessment.class_id).await?;
        let is_own = user_id == student_id;

        if !is_teacher && !is_own {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let submission = self.assessment_repo
            .find_by_student_and_assessment(student_id, assessment_id).await?;

        let result = if let Some(sub) = submission {
            let student = self.user_repo.find_by_id(sub.user_id).await?
                .ok_or_else(|| AppError::NotFound("Student not found".to_string()))?;
            let earned_score = sub.total_points;
            Some(SubmissionSummaryResponse {
                id: sub.id,
                student_id: sub.user_id,
                student_name: student.full_name,
                student_username: student.username,
                started_at: sub.started_at.to_string(),
                submitted_at: sub.submitted_at.map(|dt| dt.to_string()),
                total_points: sub.total_points,
                auto_score: earned_score,
                final_score: earned_score,
            })
        } else {
            None
        };

        Ok(result)
    }
}
