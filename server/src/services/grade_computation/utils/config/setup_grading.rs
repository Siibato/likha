use uuid::Uuid;
use crate::schema::grading_schema::ClassGradingSetupResponse;
use crate::utils::AppResult;

impl crate::services::grade_computation::GradeComputationService {
    pub async fn setup_grading(
        &self,
        class_id: Uuid,
        _grade_level: String,
        subject_group: String,
        _school_year: String,
        _semester: Option<i32>,
    ) -> AppResult<ClassGradingSetupResponse> {
        self.repo.setup_defaults(class_id, &subject_group).await?;
        self.get_grading_config(class_id).await
    }
}
