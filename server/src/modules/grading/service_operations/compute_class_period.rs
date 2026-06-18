use futures::future::try_join_all;
use uuid::Uuid;
use crate::modules::grading::schema::PeriodGradeResponse;
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn compute_class_period(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Vec<PeriodGradeResponse>> {
        let enrolled_students = self.repo.get_enrolled_student_ids(class_id).await?;
        let futures = enrolled_students
            .iter()
            .map(|(student_id, _)| self.compute_student_period(class_id, *student_id, grading_period_number));
        let result = try_join_all(futures).await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_class_grades(class_id, grading_period_number).await;
            for (student_id, _) in &enrolled_students {
                inv.invalidate_student_grades(class_id, *student_id, grading_period_number).await;
            }
        }
        Ok(result)
    }
}
