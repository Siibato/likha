use uuid::Uuid;
use crate::schema::grading_schema::GradeScoreResponse;
use crate::utils::AppResult;

impl crate::services::grade_computation::GradeComputationService {
    pub async fn clear_override(&self, score_id: Uuid) -> AppResult<GradeScoreResponse> {
        let score = self.repo.clear_override(score_id).await?;
        Ok(GradeScoreResponse::from(score))
    }
}
