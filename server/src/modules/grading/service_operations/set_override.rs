use uuid::Uuid;
use crate::modules::grading::schema::GradeScoreResponse;
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn set_override(
        &self,
        score_id: Uuid,
        override_score: f64,
    ) -> AppResult<GradeScoreResponse> {
        let score = self.repo.set_override(score_id, override_score).await?;
        if let Some(ref inv) = self.invalidator {
            if let Some(item) = self.repo.find_item(score.grade_item_id).await? {
                let class_id = item.class_id;
                let quarter = item.grading_period_number.unwrap_or(1);
                inv.invalidate_item_scores(score.grade_item_id).await;
                inv.invalidate_class_grades(class_id, quarter).await;
                inv.invalidate_student_grades(class_id, score.student_id, quarter).await;
            }
        }
        Ok(GradeScoreResponse::from(score))
    }
}
