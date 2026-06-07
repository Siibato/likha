use uuid::Uuid;
use crate::cache::CacheKey;
use crate::modules::grading::schema::PeriodGradeResponse;
use crate::utils::{AppError, AppResult};

impl crate::modules::grading::service::GradeComputationService {
    pub async fn get_student_quarterly_grade(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<PeriodGradeResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::StudentQuarterlyGrade(class_id, student_id, grading_period_number).as_str();
            if let Some(cached) = cache.get::<PeriodGradeResponse>(&key).await {
                return Ok(cached);
            }
        }
        let grade = self
            .repo
            .get_period_grade(class_id, student_id, grading_period_number)
            .await?
            .ok_or_else(|| AppError::NotFound("Grade not found for this period".to_string()))?;
        let result = PeriodGradeResponse::from(grade);
        if let Some(ref cache) = self.cache {
            let key = CacheKey::StudentQuarterlyGrade(class_id, student_id, grading_period_number).as_str();
            cache.set(&key, &result, cache.ttl.detail_seconds).await;
        }
        Ok(result)
    }
}
