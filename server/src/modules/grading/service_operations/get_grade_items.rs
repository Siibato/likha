use uuid::Uuid;
use crate::cache::CacheKey;
use crate::modules::grading::schema::GradeItemResponse;
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn get_grade_items(
        &self,
        class_id: Uuid,
        term_number: i32,
    ) -> AppResult<Vec<GradeItemResponse>> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::GradeItems(class_id, term_number).as_str();
            if let Some(cached) = cache.get::<Vec<GradeItemResponse>>(&key).await {
                return Ok(cached);
            }
        }
        let items = self.repo.get_items(class_id, term_number).await?;
        let result: Vec<GradeItemResponse> = items.into_iter().map(GradeItemResponse::from).collect();
        if let Some(ref cache) = self.cache {
            let key = CacheKey::GradeItems(class_id, term_number).as_str();
            cache.set(&key, &result, cache.ttl.list_seconds).await;
        }
        Ok(result)
    }
}
