use crate::modules::grading::schema::GradingConfigResponse;
use crate::utils::AppResult;
use uuid::Uuid;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn update_grading_config(
        &self,
        class_id: Uuid,
        term_number: i32,
        ww_weight: f64,
        pt_weight: f64,
        qa_weight: f64,
    ) -> AppResult<GradingConfigResponse> {
        let config = self
            .repo
            .upsert_config(class_id, term_number, ww_weight, pt_weight, qa_weight)
            .await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_class_grades(class_id, term_number).await;
        }
        Ok(GradingConfigResponse::from(config))
    }
}
