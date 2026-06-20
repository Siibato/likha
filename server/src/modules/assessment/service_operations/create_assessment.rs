use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::utils::{parse_datetime, fmt_utc, validators::Validator};
use crate::modules::assessment::schema::*;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn create_assessment(
        &self,
        class_id: Uuid,
        request: CreateAssessmentRequest,
        teacher_id: Uuid,
        client_id: Option<Uuid>,
    ) -> AppResult<AssessmentResponse> {
        let _ = self.class_repo.find_by_id(class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden("You can only create assessments in your own classes".to_string()));
        }

        let title = Validator::validate_title(&request.title)?;

        let open_at = parse_datetime(&request.open_at)?;
        let close_at = parse_datetime(&request.close_at)?;

        if close_at <= open_at {
            return Err(AppError::BadRequest("Close date must be after open date".to_string()));
        }

        let max_order = self.assessment_repo.get_max_order_index(class_id).await?;
        let order_index = max_order + 1;

        let assessment = self.assessment_repo.create_assessment(
            class_id,
            title,
            request.description,
            request.time_limit_minutes,
            open_at,
            close_at,
            request.show_results_immediately.unwrap_or(true),
            order_index,
            client_id,
            request.is_published.unwrap_or(false),
            request.term_number,
            request.component.clone(),
            request.tos_id,
        ).await?;


        let question_count = if let Some(questions) = request.questions {
            if !questions.is_empty() {
                let created = self.insert_questions_for_assessment(assessment.id, questions, teacher_id).await?;
                created.len() as usize
            } else {
                0
            }
        } else {
            0
        };

        if let Some(ref inv) = self.invalidator {
            inv.invalidate_assessments(teacher_id, class_id).await;
            inv.invalidate_assessment_detail(assessment.id).await;
        }
        Ok(AssessmentResponse {
            id: assessment.id,
            class_id: assessment.class_id,
            title: assessment.title,
            description: assessment.description,
            time_limit_minutes: assessment.time_limit_minutes,
            open_at: fmt_utc(assessment.open_at),
            close_at: fmt_utc(assessment.close_at),
            show_results_immediately: assessment.show_results_immediately,
            results_released: assessment.results_released,
            is_published: assessment.is_published,
            order_index: assessment.order_index,
            total_points: assessment.total_points,
            question_count,
            submission_count: 0,
            term_number: assessment.term_number,
            component: assessment.component.clone(),
            tos_id: assessment.tos_id.clone(),
            created_at: fmt_utc(assessment.created_at),
            updated_at: fmt_utc(assessment.updated_at),
        })
    }
}
