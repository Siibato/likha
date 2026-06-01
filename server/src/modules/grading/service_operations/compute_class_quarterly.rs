use uuid::Uuid;
use crate::modules::grading::schema::QuarterlyGradeResponse;
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn compute_class_quarterly(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Vec<QuarterlyGradeResponse>> {
        let student_ids = self.repo.get_enrolled_student_ids(class_id).await?;
        let mut results = Vec::new();
        for student_id in student_ids {
            let result = self
                .compute_student_quarterly(class_id, student_id, grading_period_number)
                .await?;
            results.push(result);
        }
        Ok(results)
    }
}
