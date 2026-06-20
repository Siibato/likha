use uuid::Uuid;
use crate::cache::CacheKey;
use crate::modules::grading::schema::TermGradeResponse;
use crate::utils::{AppError, AppResult};

impl crate::modules::grading::service::GradeComputationService {
    pub async fn get_student_term_grade(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        term_number: i32,
    ) -> AppResult<TermGradeResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::StudentTermGrade(class_id, student_id, term_number).as_str();
            if let Some(cached) = cache.get::<TermGradeResponse>(&key).await {
                return Ok(cached);
            }
        }
        let grade = self
            .repo
            .get_term_grade(class_id, student_id, term_number)
            .await?
            .ok_or_else(|| AppError::NotFound("Grade not found for this period".to_string()))?;
        let result = TermGradeResponse::from(grade);
        if let Some(ref cache) = self.cache {
            let key = CacheKey::StudentTermGrade(class_id, student_id, term_number).as_str();
            cache.set(&key, &result, cache.ttl.detail_seconds).await;
        }
        Ok(result)
    }
}
