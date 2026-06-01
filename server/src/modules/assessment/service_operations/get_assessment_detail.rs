use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::utils::fmt_utc;
use crate::modules::assessment::schema::*;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn get_assessment_detail(
        &self,
        assessment_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<AssessmentDetailResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if role == "student" && !assessment.is_published {
            return Err(AppError::NotFound("Assessment not found".to_string()));
        }

        if role == "teacher" && !self.class_repo.is_teacher_of_class(user_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let questions = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?;

        let mut question_responses = Vec::new();
        for q in questions {
            let question_response = self.build_question_response(&q, role).await?;
            question_responses.push(question_response);
        }

        Ok(AssessmentDetailResponse {
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
            grading_period_number: assessment.grading_period_number,
            component: assessment.component.clone(),
            tos_id: assessment.tos_id.clone(),
            questions: question_responses,
            created_at: fmt_utc(assessment.created_at),
            updated_at: fmt_utc(assessment.updated_at),
        })
    }
}
