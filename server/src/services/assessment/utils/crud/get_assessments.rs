use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::utils::fmt_utc;
use crate::schema::assessment_schema::*;

impl crate::services::assessment::AssessmentService {
    pub async fn get_assessments(
        &self,
        class_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<AssessmentListResponse> {
        let _ = self.class_repo.find_by_id(class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        let is_teacher_of_class = role == "teacher" && self.class_repo.is_teacher_of_class(user_id, class_id).await?;
        let assessments = if is_teacher_of_class {
            self.assessment_repo.find_by_class_id(class_id).await?
        } else {
            self.assessment_repo.find_published_by_class_id(class_id).await?
        };

        let mut responses = Vec::new();
        for a in assessments {
            let question_count = self.assessment_repo
                .find_questions_by_assessment_id(a.id).await?.len();
            let submission_count = self.assessment_repo
                .count_submissions_by_assessment_id(a.id).await?;

            responses.push(AssessmentResponse {
                id: a.id,
                class_id: a.class_id,
                title: a.title,
                description: a.description,
                time_limit_minutes: a.time_limit_minutes,
                open_at: fmt_utc(a.open_at),
                close_at: fmt_utc(a.close_at),
                show_results_immediately: a.show_results_immediately,
                results_released: a.results_released,
                is_published: a.is_published,
                order_index: a.order_index,
                total_points: a.total_points,
                question_count,
                submission_count,
                grading_period_number: a.grading_period_number,
                component: a.component.clone(),
                tos_id: a.tos_id.clone(),
                created_at: fmt_utc(a.created_at),
                updated_at: fmt_utc(a.updated_at),
            });
        }

        Ok(AssessmentListResponse { assessments: responses })
    }
}
