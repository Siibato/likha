use uuid::Uuid;
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn delete_grade_item(&self, id: Uuid) -> AppResult<()> {
        let existing = self.repo.find_item(id).await?;
        self.repo.soft_delete_item(id).await?;
        if let Some(ref inv) = self.invalidator {
            if let Some(ref existing) = existing {
                let class_id = existing.class_id;
                let period = existing.term_number.unwrap_or(1);
                inv.invalidate_class_grades(class_id, period).await;
            }
        }
        Ok(())
    }
}
