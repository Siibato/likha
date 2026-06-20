use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::utils::{parse_datetime, fmt_utc, validators::Validator};
use crate::modules::assessment::schema::*;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn update_assessment(
        &self,
        assessment_id: Uuid,
        request: UpdateAssessmentRequest,
        teacher_id: Uuid,
    ) -> AppResult<AssessmentResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if assessment.is_published {
            return Err(AppError::BadRequest("Cannot edit a published assessment".to_string()));
        }

        let title = Validator::validate_optional_title(request.title)?;

        let open_at = match &request.open_at {
            Some(s) => Some(parse_datetime(s)?),
            None => None,
        };
        let close_at = match &request.close_at {
            Some(s) => Some(parse_datetime(s)?),
            None => None,
        };

        let updated = self.assessment_repo.update_assessment(
            assessment_id,
            title,
            request.description,
            request.time_limit_minutes,
            open_at,
            close_at,
            request.show_results_immediately,
            request.term_number.map(|q| Some(q)),
            request.component.clone().map(|c| Some(c)),
            request.tos_id,
        ).await?;

        let question_count = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?.len();
        let submission_count = self.assessment_repo
            .count_submissions_by_assessment_id(assessment_id).await?;

        if let Some(ref inv) = self.invalidator {
            inv.invalidate_assessment_detail(assessment_id).await;
            inv.invalidate_assessments(teacher_id, assessment.class_id).await;
        }

        Ok(AssessmentResponse {
            id: updated.id,
            class_id: updated.class_id,
            title: updated.title,
            description: updated.description,
            time_limit_minutes: updated.time_limit_minutes,
            open_at: fmt_utc(updated.open_at),
            close_at: fmt_utc(updated.close_at),
            show_results_immediately: updated.show_results_immediately,
            results_released: updated.results_released,
            is_published: updated.is_published,
            order_index: updated.order_index,
            total_points: updated.total_points,
            question_count,
            submission_count,
            term_number: updated.term_number,
            component: updated.component.clone(),
            tos_id: updated.tos_id.clone(),
            created_at: fmt_utc(updated.created_at),
            updated_at: fmt_utc(updated.updated_at),
        })
    }
}
