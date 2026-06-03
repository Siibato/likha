use uuid::Uuid;
use crate::modules::grading::schema::{FinalGradeResponse, QuarterlyGradeResponse};
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn compute_final_grade(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<FinalGradeResponse> {
        let quarters = self
            .repo
            .get_all_for_student(class_id, student_id)
            .await?;

        let period_responses: Vec<QuarterlyGradeResponse> =
            quarters.into_iter().map(QuarterlyGradeResponse::from).collect();

        let locked_grades: Vec<f64> = period_responses
            .iter()
            .filter(|q| q.is_locked)
            .filter_map(|q| q.transmuted_grade.map(|t| t as f64))
            .collect();

        let final_grade = if locked_grades.is_empty() {
            None
        } else {
            Some(locked_grades.iter().sum::<f64>() / locked_grades.len() as f64)
        };

        Ok(FinalGradeResponse {
            student_id: student_id.to_string(),
            period_grades: period_responses,
            final_grade,
        })
    }
}
