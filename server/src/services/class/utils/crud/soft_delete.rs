use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};

impl crate::services::class::ClassService {
    pub async fn soft_delete(&self, class_id: Uuid, user_id: Uuid, role: &str) -> AppResult<()> {
        let _class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if role != "admin" && !self.class_repo.is_teacher_of_class(user_id, class_id).await? {
            return Err(AppError::Forbidden(
                "You can only delete your own classes".to_string(),
            ));
        }

        self.class_repo.remove_all_participants(class_id).await?;
        self.class_repo.soft_delete(class_id).await?;

        Ok(())
    }
}
