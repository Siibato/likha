use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::auth_schema::{LockAccountRequest, UserResponse};

impl crate::services::auth::AuthService {
    pub async fn lock_account(&self, request: LockAccountRequest, admin_id: Uuid) -> AppResult<UserResponse> {
        let user = self.user_repo.find_by_id(request.user_id).await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        let new_status = if request.locked { "locked" } else { "active" };

        let updated = self.user_repo.update_account_status(request.user_id, new_status).await?;

        let action = if request.locked { "account_locked" } else { "account_unlocked" };
        let _ = self.activity_log_repo
            .create_log(
                admin_id,
                action,
                Some(format!("{} account '{}'", action, user.username)),
            )
            .await;

        Ok(Self::user_to_response(&updated))
    }
}
