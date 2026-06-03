use uuid::Uuid;
use crate::modules::grading::schema::GradeScoreResponse;
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn get_item_scores(&self, grade_item_id: Uuid) -> AppResult<Vec<GradeScoreResponse>> {
        let scores = self.repo.get_scores_by_item(grade_item_id).await?;
        Ok(scores.into_iter().map(GradeScoreResponse::from).collect())
    }
}
