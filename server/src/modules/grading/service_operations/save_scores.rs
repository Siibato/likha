use uuid::Uuid;
use crate::modules::grading::schema::GradeScoreResponse;
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn save_scores(
        &self,
        grade_item_id: Uuid,
        scores: Vec<(Uuid, f64)>,
    ) -> AppResult<Vec<GradeScoreResponse>> {
        let item = self.repo.find_item(grade_item_id).await?;
        self.repo.bulk_upsert_scores(grade_item_id, scores.clone()).await?;
        if let Some(ref inv) = self.invalidator {
            if let Some(ref item) = item {
                let class_id = item.class_id;
                let period = item.grading_period_number.unwrap_or(1);
                inv.invalidate_item_scores(grade_item_id).await;
                inv.invalidate_class_grades(class_id, period).await;
                for (student_id, _) in &scores {
                    inv.invalidate_student_grades(class_id, *student_id, period).await;
                }
            }
        }
        self.get_item_scores(grade_item_id).await
    }
}
