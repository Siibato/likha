use uuid::Uuid;
use crate::modules::grading::schema::{ClassGradingSetupResponse, GradingConfigResponse};
use crate::utils::{AppError, AppResult};

impl crate::modules::grading::service::GradeComputationService {
    pub async fn get_grading_config(&self, class_id: Uuid) -> AppResult<ClassGradingSetupResponse> {
        let configs = self.repo.get_all_configs(class_id).await?;
        let class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;
        Ok(ClassGradingSetupResponse {
            class_id: class_id.to_string(),
            grade_level: class.grade_level.unwrap_or_default(),
            school_year: class.school_year.unwrap_or_default(),
            term_type: class.term_type,
            configs: configs.into_iter().map(GradingConfigResponse::from).collect(),
        })
    }
}
