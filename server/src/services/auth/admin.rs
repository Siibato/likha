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
        admin_id: Uuid,
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
            .create_log(user.id, action, Some(admin_id), request.reason.clone())
            .await?;

        let _ = self.change_log_repo.log_change(
            "user",
            request.user_id,
            "update",
            admin_id,
            Some(serde_json::to_string(&serde_json::json!({
                "account_status": status,
            })).unwrap_or_default()),
        ).await;

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
                performed_by: log.performed_by,
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
}