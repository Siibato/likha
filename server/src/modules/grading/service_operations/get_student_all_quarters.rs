use uuid::Uuid;
use crate::cache::CacheKey;
use crate::modules::grading::schema::PeriodGradeResponse;
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn get_student_all_quarters(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<Vec<PeriodGradeResponse>> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::StudentAllGrades(class_id, student_id).as_str();
            if let Some(cached) = cache.get::<Vec<PeriodGradeResponse>>(&key).await {
                return Ok(cached);
            }
        }
        let grades = self.repo.get_all_for_student(class_id, student_id).await?;
        let result: Vec<PeriodGradeResponse> = grades.into_iter().map(PeriodGradeResponse::from).collect();
        if let Some(ref cache) = self.cache {
            let key = CacheKey::StudentAllGrades(class_id, student_id).as_str();
            cache.set(&key, &result, cache.ttl.list_seconds).await;
        }
        Ok(result)
    }
}
