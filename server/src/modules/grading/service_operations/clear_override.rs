use uuid::Uuid;
use crate::modules::grading::schema::GradeScoreResponse;
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn clear_override(&self, score_id: Uuid) -> AppResult<GradeScoreResponse> {
        let score = self.repo.clear_override(score_id).await?;
        if let Some(ref inv) = self.invalidator {
            if let Some(item) = self.repo.find_item(score.grade_item_id).await? {
                let class_id = item.class_id;
                let term = item.term_number.unwrap_or(1);
                inv.invalidate_item_scores(score.grade_item_id).await;
                inv.invalidate_class_grades(class_id, term).await;
                inv.invalidate_student_grades(class_id, score.student_id, term).await;
            }
        }
        Ok(GradeScoreResponse::from(score))
    }
}
