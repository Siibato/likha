use uuid::Uuid;
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn delete_grade_item(&self, id: Uuid) -> AppResult<()> {
        self.repo.soft_delete_item(id).await
    }
}
