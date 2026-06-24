use crate::cache::CacheKey;
use crate::modules::grading::schema::TermGradeResponse;
use crate::utils::AppResult;
use uuid::Uuid;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn get_term_grades(
        &self,
        class_id: Uuid,
        term_number: i32,
    ) -> AppResult<Vec<TermGradeResponse>> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::TermGrades(class_id, term_number).as_str();
            if let Some(cached) = cache.get::<Vec<TermGradeResponse>>(&key).await {
                return Ok(cached);
            }
        }
        let grades = self.repo.get_all_for_class(class_id, term_number).await?;
        let result: Vec<TermGradeResponse> =
            grades.into_iter().map(TermGradeResponse::from).collect();
        if let Some(ref cache) = self.cache {
            let key = CacheKey::TermGrades(class_id, term_number).as_str();
            cache.set(&key, &result, cache.ttl.list_seconds).await;
        }
        Ok(result)
    }
}
