use uuid::Uuid;
use crate::schema::grading_schema::GradingConfigResponse;
use crate::utils::AppResult;

impl crate::services::grade_computation::GradeComputationService {
    pub async fn update_grading_config(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
        ww_weight: f64,
        pt_weight: f64,
        qa_weight: f64,
    ) -> AppResult<GradingConfigResponse> {
        let config = self
            .repo
            .upsert_config(class_id, grading_period_number, ww_weight, pt_weight, qa_weight)
            .await?;
        Ok(GradingConfigResponse::from(config))
    }
}
