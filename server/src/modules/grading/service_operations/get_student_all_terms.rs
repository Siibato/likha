use crate::cache::CacheKey;
use crate::modules::grading::schema::TermGradeResponse;
use crate::utils::AppResult;
use uuid::Uuid;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn get_student_all_terms(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<Vec<TermGradeResponse>> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::StudentAllGrades(class_id, student_id).as_str();
            if let Some(cached) = cache.get::<Vec<TermGradeResponse>>(&key).await {
                return Ok(cached);
            }
        }
        let grades = self.repo.get_all_for_student(class_id, student_id).await?;
        let result: Vec<TermGradeResponse> =
            grades.into_iter().map(TermGradeResponse::from).collect();
        if let Some(ref cache) = self.cache {
            let key = CacheKey::StudentAllGrades(class_id, student_id).as_str();
            cache.set(&key, &result, cache.ttl.list_seconds).await;
        }
        Ok(result)
    }
}
