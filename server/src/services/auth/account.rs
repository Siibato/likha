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
        _admin_id: Uuid,
        client_id: Option<Uuid>,
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
                client_id,
            )
            .await?;

        self.activity_log_repo
            .create_log(
                user.id,
                "account_created",
                Some(format!("Account created with role: {}", user.role)),
            )
            .await?;

        Ok(Self::user_to_response(&user))
    }

    pub async fn update_account(
        &self,
        user_id: Uuid,
        request: UpdateAccountRequest,
        admin_id: Uuid,
    ) -> AppResult<UserResponse> {
        if request.full_name.is_none() && request.role.is_none() {
            return Err(AppError::BadRequest("No fields to update".to_string()));
        }

        if let Some(ref full_name) = request.full_name {
            if full_name.trim().is_empty() {
                return Err(AppError::BadRequest("Full name is required".to_string()));
            }
        }

        if let Some(ref role) = request.role {
            Validator::validate_role(role)?;
            if user_id == admin_id {
                return Err(AppError::Forbidden(
                    "Admins cannot change their own role".to_string(),
                ));
            }
        }

        let has_role_update = request.role.is_some();

        let user = self
            .user_repo
            .update_account(user_id, request.full_name.map(|n| n.trim().to_string()), request.role)
            .await?;

        if has_role_update {
            let _ = self.user_repo.revoke_all_tokens_for_user(user_id).await;
        }

        let log_message = if has_role_update {
            "Account role updated; sessions revoked"
        } else {
            "Account details updated"
        };

        self.activity_log_repo
            .create_log(
                user.id,
                "account_updated",
                Some(log_message.to_string()),
            )
            .await?;

        Ok(Self::user_to_response(&user))
    }

    pub async fn reset_account(
        &self,
        request: ResetAccountRequest,
        _admin_id: Uuid,
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
                Some("Account reset to pending activation".to_string()),
            )
            .await?;

        Ok(Self::user_to_response(&user))
    }

    pub async fn get_account(&self, user_id: Uuid) -> AppResult<UserResponse> {
        let user = self
            .user_repo
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;
        Ok(Self::user_to_response(&user))
    }
}