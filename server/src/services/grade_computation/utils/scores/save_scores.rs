use uuid::Uuid;
use crate::schema::grading_schema::GradeScoreResponse;
use crate::utils::AppResult;

impl crate::services::grade_computation::GradeComputationService {
    pub async fn save_scores(
        &self,
        grade_item_id: Uuid,
        scores: Vec<(Uuid, f64)>,
    ) -> AppResult<Vec<GradeScoreResponse>> {
        self.repo.bulk_upsert_scores(grade_item_id, scores).await?;
        self.get_item_scores(grade_item_id).await
    }
}
