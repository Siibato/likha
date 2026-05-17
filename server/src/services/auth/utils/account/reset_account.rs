use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::auth_schema::{ResetAccountRequest, UserResponse};

impl crate::services::auth::AuthService {
    pub async fn reset_account(&self, request: ResetAccountRequest, admin_id: Uuid) -> AppResult<UserResponse> {
        let user = self.user_repo.find_by_id(request.user_id).await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        self.user_repo.clear_password(request.user_id).await?;
        let updated = self.user_repo.update_account_status(request.user_id, "pending_activation").await?;

        let _ = self.activity_log_repo
            .create_log(
                admin_id,
                "account_reset",
                Some(format!("Reset account '{}'", user.username)),
            )
            .await;

        Ok(Self::user_to_response(&updated))
    }
}
