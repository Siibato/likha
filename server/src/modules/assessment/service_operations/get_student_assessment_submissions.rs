use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::assessment::schema::*;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn get_student_assessment_submissions(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<StudentAssessmentSubmissionsResponse> {
        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden("Teacher access required".to_string()));
        }

        let assessments = self.assessment_repo.find_published_by_class_id(class_id).await?;

        let mut items = Vec::new();
        for assessment in assessments {
            if let Some(sub) = self.assessment_repo
                .find_by_student_and_assessment(student_id, assessment.id).await? {
                let student = self.user_repo.find_by_id(sub.user_id).await?
                    .ok_or_else(|| AppError::NotFound("Student not found".to_string()))?;
                items.push(StudentAssessmentSubmissionItem {
                    assessment_id: assessment.id,
                    id: sub.id,
                    student_id: sub.user_id,
                    student_name: student.full_name.clone(),
                    student_username: student.username.clone(),
                    started_at: sub.started_at.to_string(),
                    submitted_at: sub.submitted_at.map(|dt| dt.to_string()),
                    total_points: sub.total_points,
                });
            }
        }

        Ok(StudentAssessmentSubmissionsResponse { submissions: items })
    }
}
