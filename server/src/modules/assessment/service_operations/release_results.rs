use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::utils::fmt_utc;
use crate::modules::assessment::schema::*;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn release_results(
        &self,
        assessment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<AssessmentResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if !assessment.is_published {
            return Err(AppError::BadRequest("Assessment must be published first".to_string()));
        }

        let released = self.assessment_repo.release_results(assessment_id).await?;

        let question_count = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?.len();
        let submission_count = self.assessment_repo
            .count_submissions_by_assessment_id(assessment_id).await?;

        Ok(AssessmentResponse {
            id: released.id,
            class_id: released.class_id,
            title: released.title,
            description: released.description,
            time_limit_minutes: released.time_limit_minutes,
            open_at: fmt_utc(released.open_at),
            close_at: fmt_utc(released.close_at),
            show_results_immediately: released.show_results_immediately,
            results_released: released.results_released,
            is_published: released.is_published,
            order_index: released.order_index,
            total_points: released.total_points,
            question_count,
            submission_count,
            term_number: released.term_number,
            component: released.component.clone(),
            tos_id: released.tos_id.map(|u| u.to_string()),
            created_at: fmt_utc(released.created_at),
            updated_at: fmt_utc(released.updated_at),
        })
    }
}
