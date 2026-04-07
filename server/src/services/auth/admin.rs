use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::auth_schema::UserResponse;
use crate::schema::admin_schema::{AccountListResponse, ActivityLogListResponse, ActivityLogResponse};

impl super::AuthService {
    pub async fn get_all_accounts(&self) -> AppResult<AccountListResponse> {
        let users = self.user_repo.find_all_users().await?;
        let total = users.len();
        let accounts = users.iter().map(Self::user_to_response).collect();

        Ok(AccountListResponse { accounts, total })
    }

    pub async fn lock_account(
        &self,
        request: crate::schema::auth_schema::LockAccountRequest,
        _admin_id: Uuid,
    ) -> AppResult<UserResponse> {
        let user = self
            .user_repo
            .find_by_id(request.user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        let (status, action) = if request.locked {
            ("locked", "account_locked")
        } else {
            if user.password_hash.is_some() {
                ("activated", "account_unlocked")
            } else {
                ("pending_activation", "account_unlocked")
            }
        };

        let user = self.user_repo.update_account_status(user.id, status).await?;

        self.activity_log_repo
            .create_log(user.id, action, request.reason.clone())
            .await?;

        Ok(Self::user_to_response(&user))
    }

    pub async fn get_activity_logs(
        &self,
        user_id: Uuid,
    ) -> AppResult<ActivityLogListResponse> {
        self.user_repo
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        let logs = self.activity_log_repo.find_by_user_id(user_id).await?;

        let logs = logs
            .into_iter()
            .map(|log| ActivityLogResponse {
                id: log.id,
                user_id: log.user_id,
                action: log.action,
                details: log.details,
                created_at: log.created_at.to_string(),
            })
            .collect();

        Ok(ActivityLogListResponse { logs })
    }

    pub async fn search_students(&self, query: &str) -> AppResult<Vec<UserResponse>> {
        let students = self.user_repo.search_students(query).await?;
        Ok(students.iter().map(Self::user_to_response).collect())
    }

    pub async fn delete_account(
        &self,
        user_id: Uuid,
        admin_id: Uuid,
    ) -> AppResult<()> {
        if user_id == admin_id {
            return Err(AppError::BadRequest("Cannot delete your own account".to_string()));
        }

        let user = self
            .user_repo
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        if user.role == "admin" {
            return Err(AppError::Forbidden("Cannot delete admin accounts".to_string()));
        }

        // Revoke all refresh tokens
        self.user_repo.revoke_all_tokens_for_user(user_id).await?;

        // Soft-delete the user
        self.user_repo.soft_delete(user_id).await?;

        // Log the action
        self.activity_log_repo
            .create_log(user_id, "account_deleted", Some(format!("Deleted by admin")))
            .await?;

        Ok(())
    }
}