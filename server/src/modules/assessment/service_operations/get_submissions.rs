use futures::future::try_join_all;
use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::assessment::schema::*;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn get_submissions(
        &self,
        assessment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<SubmissionListResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let submissions = self.assessment_repo
            .find_submissions_by_assessment_id(assessment_id).await?;

        let response_futures = submissions.into_iter().map(|s| async move {
            let student = self.user_repo.find_by_id(s.user_id).await?
                .ok_or_else(|| AppError::NotFound("Student not found".to_string()))?;

            let earned_score = s.total_points;

            Ok::<SubmissionSummaryResponse, AppError>(SubmissionSummaryResponse {
                id: s.id,
                student_id: s.user_id,
                student_name: student.full_name,
                student_username: student.username,
                started_at: s.started_at.to_string(),
                submitted_at: s.submitted_at.map(|dt| dt.to_string()),
                total_points: s.total_points,
                auto_score: earned_score,
                final_score: earned_score,
            })
        });

        let submissions = try_join_all(response_futures).await?;
        Ok(SubmissionListResponse { submissions })
    }
}
