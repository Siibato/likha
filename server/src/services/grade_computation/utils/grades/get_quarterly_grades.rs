use uuid::Uuid;
use crate::schema::grading_schema::PeriodGradeResponse;
use crate::utils::AppResult;

impl crate::services::grade_computation::GradeComputationService {
    pub async fn get_quarterly_grades(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Vec<PeriodGradeResponse>> {
        let grades = self.repo.get_all_for_class(class_id, grading_period_number).await?;
        Ok(grades.into_iter().map(PeriodGradeResponse::from).collect())
    }
}
