use std::collections::HashMap;
use futures::future::try_join_all;
use uuid::Uuid;
use crate::modules::grading::schema::{AllGradeDataResponse, GradingConfigResponse};
use crate::utils::{AppError, AppResult};

impl crate::modules::grading::service::GradeComputationService {
    pub async fn get_all_grade_data(
        &self,
        class_id: Uuid,
        period: i32,
    ) -> AppResult<AllGradeDataResponse> {
        let (items, summary, config) = tokio::try_join!(
            self.get_grade_items(class_id, period),
            self.get_grade_summary(class_id, period),
            self.repo.get_config(class_id, period),
        )?;

        let config = config.map(GradingConfigResponse::from);

        let score_futures = items.iter().map(|item| async {
            let item_id = match Uuid::parse_str(&item.id) {
                Ok(id) => id,
                Err(_) => return Ok::<_, AppError>((item.id.clone(), vec![])),
            };
            let scores = self.get_item_scores(item_id).await?;
            Ok((item.id.clone(), scores))
        });

        let scores_by_item: HashMap<String, Vec<_>> =
            try_join_all(score_futures).await?.into_iter().collect();

        Ok(AllGradeDataResponse {
            grade_items: items,
            grade_summary: summary,
            period,
            scores_by_item,
            config,
        })
    }
}
