use uuid::Uuid;
use crate::modules::grading::schema::GradeItemResponse;
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn get_grade_items(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Vec<GradeItemResponse>> {
        let items = self.repo.get_items(class_id, grading_period_number).await?;
        Ok(items.into_iter().map(GradeItemResponse::from).collect())
    }
}
