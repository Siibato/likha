use crate::modules::assessment::schema::*;
use crate::modules::grading::helpers::auto_populate;
use crate::utils::error::{AppError, AppResult};
use crate::utils::fmt_utc;
use uuid::Uuid;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn publish_assessment(
        &self,
        assessment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<AssessmentResponse> {
        let assessment = self
            .assessment_repo
            .find_by_id(assessment_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self
            .class_repo
            .find_by_id(assessment.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self
            .class_repo
            .is_teacher_of_class(teacher_id, assessment.class_id)
            .await?
        {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if assessment.is_published {
            return Err(AppError::BadRequest(
                "Assessment is already published".to_string(),
            ));
        }

        let questions = self
            .assessment_repo
            .find_questions_by_assessment_id(assessment_id)
            .await?;
        if questions.is_empty() {
            return Err(AppError::BadRequest(
                "Cannot publish assessment with no questions".to_string(),
            ));
        }

        self.assessment_repo
            .update_total_points(assessment_id)
            .await?;
        let published = self
            .assessment_repo
            .publish_assessment(assessment_id)
            .await?;

        if let (Some(term), Some(ref component)) = (published.term_number, &published.component) {
            let _ = auto_populate::create_linked_grade_item(
                &self.grade_computation_repo,
                "assessment",
                published.id,
                published.class_id,
                &published.title,
                component,
                term,
                published.total_points as f64,
            )
            .await;
        }

        let question_count = questions.len();
        let submission_count = self
            .assessment_repo
            .count_submissions_by_assessment_id(assessment_id)
            .await?;

        if let Some(ref inv) = self.invalidator {
            inv.invalidate_assessment_detail(assessment_id).await;
            inv.invalidate_assessments(teacher_id, assessment.class_id)
                .await;
        }

        Ok(AssessmentResponse {
            id: published.id,
            class_id: published.class_id,
            title: published.title,
            description: published.description,
            time_limit_minutes: published.time_limit_minutes,
            open_at: fmt_utc(published.open_at),
            close_at: fmt_utc(published.close_at),
            show_results_immediately: published.show_results_immediately,
            results_released: published.results_released,
            is_published: published.is_published,
            order_index: published.order_index,
            total_points: published.total_points,
            question_count,
            submission_count,
            term_number: published.term_number,
            component: published.component.clone(),
            tos_id: published.tos_id.map(|u| u.to_string()),
            created_at: fmt_utc(published.created_at),
            updated_at: fmt_utc(published.updated_at),
        })
    }
}
