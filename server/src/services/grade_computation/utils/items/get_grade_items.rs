use uuid::Uuid;
use crate::schema::grading_schema::GradeItemResponse;
use crate::utils::AppResult;

impl crate::services::grade_computation::GradeComputationService {
    pub async fn get_grade_items(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Vec<GradeItemResponse>> {
        let items = self.repo.get_items(class_id, grading_period_number).await?;
        Ok(items.into_iter().map(GradeItemResponse::from).collect())
    }
}
