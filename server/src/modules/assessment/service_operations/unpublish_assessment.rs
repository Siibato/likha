use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::utils::fmt_utc;
use crate::modules::assessment::schema::*;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn unpublish_assessment(
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
            return Err(AppError::BadRequest("Assessment is not published".to_string()));
        }

        if assessment.results_released {
            return Err(AppError::BadRequest("Cannot unpublish — results have already been released".to_string()));
        }

        let unpublished = self.assessment_repo.unpublish_assessment(assessment_id).await?;

        let question_count = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?.len();
        let submission_count = self.assessment_repo.count_submissions_by_assessment_id(assessment_id).await?;

        if let Some(ref inv) = self.invalidator {
            inv.invalidate_assessment_detail(assessment_id).await;
            inv.invalidate_assessments(teacher_id, assessment.class_id).await;
        }

        Ok(AssessmentResponse {
            id: unpublished.id,
            class_id: unpublished.class_id,
            title: unpublished.title,
            description: unpublished.description,
            time_limit_minutes: unpublished.time_limit_minutes,
            open_at: fmt_utc(unpublished.open_at),
            close_at: fmt_utc(unpublished.close_at),
            show_results_immediately: unpublished.show_results_immediately,
            results_released: unpublished.results_released,
            is_published: unpublished.is_published,
            order_index: unpublished.order_index,
            total_points: unpublished.total_points,
            question_count,
            submission_count,
            term_number: unpublished.term_number,
            component: unpublished.component.clone(),
            tos_id: unpublished.tos_id.clone(),
            created_at: fmt_utc(unpublished.created_at),
            updated_at: fmt_utc(unpublished.updated_at),
        })
    }
}
