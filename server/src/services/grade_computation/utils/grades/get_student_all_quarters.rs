use uuid::Uuid;
use crate::schema::grading_schema::PeriodGradeResponse;
use crate::utils::AppResult;

impl crate::services::grade_computation::GradeComputationService {
    pub async fn get_student_all_quarters(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<Vec<PeriodGradeResponse>> {
        let grades = self.repo.get_all_for_student(class_id, student_id).await?;
        Ok(grades.into_iter().map(PeriodGradeResponse::from).collect())
    }
}
