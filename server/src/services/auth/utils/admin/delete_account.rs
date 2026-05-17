use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};

impl crate::services::auth::AuthService {
    pub async fn delete_account(&self, user_id: Uuid, admin_id: Uuid) -> AppResult<()> {
        let user = self.user_repo.find_by_id(user_id).await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        self.user_repo.soft_delete(user_id).await?;

        let _ = self.activity_log_repo
            .create_log(
                admin_id,
                "account_deleted",
                Some(format!("Deleted account '{}'", user.username)),
            )
            .await;

        Ok(())
    }
}
