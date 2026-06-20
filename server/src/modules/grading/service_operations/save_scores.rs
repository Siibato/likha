use uuid::Uuid;
use crate::modules::grading::schema::GradeScoreResponse;
use crate::utils::{AppError, AppResult};

impl crate::modules::grading::service::GradeComputationService {
    pub async fn save_scores(
        &self,
        grade_item_id: Uuid,
        scores: Vec<(Uuid, f64)>,
    ) -> AppResult<Vec<GradeScoreResponse>> {
        tracing::info!("save_scores: grade_item_id={} scores_count={}", grade_item_id, scores.len());
        let item = self.repo.find_item(grade_item_id).await?;
        if item.is_none() {
            tracing::error!("save_scores: grade_item_id={} not found", grade_item_id);
            return Err(AppError::NotFound(format!("Grade item {} not found", grade_item_id)));
        }
        self.repo.bulk_upsert_scores(grade_item_id, scores.clone()).await?;
        if let Some(ref inv) = self.invalidator {
            if let Some(ref item) = item {
                let class_id = item.class_id;
                let period = item.term_number.unwrap_or(1);
                tracing::debug!("save_scores: invalidating cache for class_id={} period={}", class_id, period);
                inv.invalidate_item_scores(grade_item_id).await;
                inv.invalidate_class_grades(class_id, period).await;
                for (student_id, _) in &scores {
                    inv.invalidate_student_grades(class_id, *student_id, period).await;
                }
            }
        }
        tracing::info!("save_scores: completed for grade_item_id={}", grade_item_id);
        self.get_item_scores(grade_item_id).await
    }
}
