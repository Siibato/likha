use uuid::Uuid;
use crate::modules::grading::schema::PeriodGradeResponse;
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn get_student_all_quarters(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<Vec<PeriodGradeResponse>> {
        let grades = self.repo.get_all_for_student(class_id, student_id).await?;
        Ok(grades.into_iter().map(PeriodGradeResponse::from).collect())
    }
}
