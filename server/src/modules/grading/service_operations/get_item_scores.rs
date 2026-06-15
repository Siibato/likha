use uuid::Uuid;
use crate::cache::CacheKey;
use crate::modules::grading::schema::GradeScoreResponse;
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn get_item_scores(&self, grade_item_id: Uuid) -> AppResult<Vec<GradeScoreResponse>> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::ItemScores(grade_item_id).as_str();
            if let Some(cached) = cache.get::<Vec<GradeScoreResponse>>(&key).await {
                return Ok(cached);
            }
        }
        let scores = self.repo.get_scores_by_item(grade_item_id).await?;
        let result: Vec<GradeScoreResponse> = scores.into_iter().map(GradeScoreResponse::from).collect();
        if let Some(ref cache) = self.cache {
            let key = CacheKey::ItemScores(grade_item_id).as_str();
            cache.set(&key, &result, cache.ttl.list_seconds).await;
        }
        Ok(result)
    }
}
