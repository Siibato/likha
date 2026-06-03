use uuid::Uuid;
use crate::modules::grading::schema::PeriodGradeResponse;
use crate::utils::{AppError, AppResult};

impl crate::modules::grading::service::GradeComputationService {
    pub async fn get_student_quarterly_grade(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<PeriodGradeResponse> {
        let grade = self
            .repo
            .get_period_grade(class_id, student_id, grading_period_number)
            .await?
            .ok_or_else(|| AppError::NotFound("Grade not found for this period".to_string()))?;
        Ok(PeriodGradeResponse::from(grade))
    }
}
