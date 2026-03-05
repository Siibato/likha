use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::auth_schema::{
    CreateAccountRequest, UpdateAccountRequest, ResetAccountRequest, UserResponse,
};
use crate::utils::validators::Validator;

impl super::AuthService {
    pub async fn create_account(
        &self,
        request: CreateAccountRequest,
        admin_id: Uuid,
    ) -> AppResult<UserResponse> {
        Validator::validate_username(&request.username)?;
        Validator::validate_role(&request.role)?;

        if request.full_name.trim().is_empty() {
            return Err(AppError::BadRequest("Full name is required".to_string()));
        }

        if let Some(_) = self.user_repo.find_by_username(&request.username).await? {
            return Err(AppError::BadRequest("Username already taken".to_string()));
        }

        let user = self
            .user_repo
            .create_account(
                request.username,
                request.full_name.trim().to_string(),
                request.role,
            )
            .await?;

        self.activity_log_repo
            .create_log(
                user.id,
                "account_created",
                Some(admin_id),
                Some(format!("Account created with role: {}", user.role)),
            )
            .await?;

        let _ = self.change_log_repo.log_change(
            "user",
            user.id,
            "create",
            admin_id,
            Some(serde_json::to_string(&serde_json::json!({
                "username": user.username,
                "role": user.role,
            })).unwrap_or_default()),
        ).await;

        Ok(Self::user_to_response(&user))
    }

    pub async fn update_account(
        &self,
        user_id: Uuid,
        request: UpdateAccountRequest,
        admin_id: Uuid,
    ) -> AppResult<UserResponse> {
        if request.username.is_none() && request.full_name.is_none() && request.role.is_none() {
            return Err(AppError::BadRequest("No fields to update".to_string()));
        }

        if let Some(ref username) = request.username {
            Validator::validate_username(username)?;
            if let Some(existing) = self.user_repo.find_by_username(username).await? {
                if existing.id != user_id {
                    return Err(AppError::BadRequest("Username already taken".to_string()));
                }
            }
        }

        if let Some(ref full_name) = request.full_name {
            if full_name.trim().is_empty() {
                return Err(AppError::BadRequest("Full name is required".to_string()));
            }
        }

        if let Some(ref role) = request.role {
            Validator::validate_role(role)?;
        }

        let has_role_update = request.role.is_some();

        let user = self
            .user_repo
            .update_account(user_id, request.username, request.full_name.map(|n| n.trim().to_string()), request.role)
            .await?;

        self.activity_log_repo
            .create_log(
                user.id,
                "account_updated",
                Some(admin_id),
                Some("Account details updated".to_string()),
            )
            .await?;

        let mut change_log_data = serde_json::json!({
            "username": user.username,
            "full_name": user.full_name,
        });
        if has_role_update {
            change_log_data["role"] = serde_json::json!(user.role);
        }

        let _ = self.change_log_repo.log_change(
            "user",
            user_id,
            "update",
            admin_id,
            Some(serde_json::to_string(&change_log_data).unwrap_or_default()),
        ).await;

        Ok(Self::user_to_response(&user))
    }

    pub async fn reset_account(
        &self,
        request: ResetAccountRequest,
        admin_id: Uuid,
    ) -> AppResult<UserResponse> {
        let user = self
            .user_repo
            .find_by_id(request.user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        let user = self.user_repo.clear_password(user.id).await?;

        self.activity_log_repo
            .create_log(
                user.id,
                "password_reset",
                Some(admin_id),
                Some("Account reset to pending activation".to_string()),
            )
            .await?;

        let _ = self.change_log_repo.log_change(
            "user",
            request.user_id,
            "update",
            admin_id,
            Some(serde_json::to_string(&serde_json::json!({
                "account_status": "pending_activation",
            })).unwrap_or_default()),
        ).await;

        Ok(Self::user_to_response(&user))
    }
}