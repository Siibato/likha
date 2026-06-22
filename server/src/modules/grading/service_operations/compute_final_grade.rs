use uuid::Uuid;
use crate::cache::CacheKey;
use crate::modules::grading::schema::{FinalGradeResponse, TermGradeResponse};
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn compute_final_grade(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<FinalGradeResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::FinalGrade(class_id, student_id).as_str();
            if let Some(cached) = cache.get::<FinalGradeResponse>(&key).await {
                return Ok(cached);
            }
        }
        let terms = self
            .repo
            .get_all_for_student(class_id, student_id)
            .await?;

        let term_responses: Vec<TermGradeResponse> =
            terms.into_iter().map(TermGradeResponse::from).collect();

        let locked_grades: Vec<f64> = term_responses
            .iter()
            .filter(|q| q.is_locked)
            .filter_map(|q| q.transmuted_grade.map(|t| t as f64))
            .collect();

        let final_grade = if locked_grades.is_empty() {
            None
        } else {
            Some(locked_grades.iter().sum::<f64>() / locked_grades.len() as f64)
        };

        let result = FinalGradeResponse {
            student_id: student_id.to_string(),
            term_grades: term_responses,
            final_grade,
        };
        if let Some(ref cache) = self.cache {
            let key = CacheKey::FinalGrade(class_id, student_id).as_str();
            cache.set(&key, &result, cache.ttl.detail_seconds).await;
        }
        Ok(result)
    }
}
