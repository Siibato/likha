use futures::future::try_join_all;
use uuid::Uuid;
use crate::modules::grading::schema::TermGradeResponse;
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn compute_class_term(
        &self,
        class_id: Uuid,
        term_number: i32,
    ) -> AppResult<Vec<TermGradeResponse>> {
        let enrolled_students = self.repo.get_enrolled_student_ids(class_id).await?;
        let futures = enrolled_students
            .iter()
            .map(|(student_id, _)| self.compute_student_term(class_id, *student_id, term_number));
        let result = try_join_all(futures).await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_class_grades(class_id, term_number).await;
            for (student_id, _) in &enrolled_students {
                inv.invalidate_student_grades(class_id, *student_id, term_number).await;
            }
        }
        Ok(result)
    }
}
