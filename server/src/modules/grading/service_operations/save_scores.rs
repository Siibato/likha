use uuid::Uuid;
use crate::modules::grading::schema::GradeScoreResponse;
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn save_scores(
        &self,
        grade_item_id: Uuid,
        scores: Vec<(Uuid, f64)>,
    ) -> AppResult<Vec<GradeScoreResponse>> {
        self.repo.bulk_upsert_scores(grade_item_id, scores).await?;
        self.get_item_scores(grade_item_id).await
    }
}
