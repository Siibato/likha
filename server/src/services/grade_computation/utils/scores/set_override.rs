use uuid::Uuid;
use crate::schema::grading_schema::GradeScoreResponse;
use crate::utils::AppResult;

impl crate::services::grade_computation::GradeComputationService {
    pub async fn set_override(
        &self,
        score_id: Uuid,
        override_score: f64,
    ) -> AppResult<GradeScoreResponse> {
        let score = self.repo.set_override(score_id, override_score).await?;
        Ok(GradeScoreResponse::from(score))
    }
}
