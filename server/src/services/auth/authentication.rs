use chrono::{Duration, Utc};
use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::auth_schema::{
    ActivateAccountRequest, AuthResponse, CheckUsernameRequest, CheckUsernameResponse, LoginRequest,
};
use crate::utils::password::PasswordService;
use crate::utils::validators::Validator;

impl super::AuthService {
    pub async fn check_username(
        &self,
        request: CheckUsernameRequest,
    ) -> AppResult<CheckUsernameResponse> {
        let user = self
            .user_repo
            .find_by_username(&request.username)
            .await?
            .ok_or_else(|| AppError::NotFound("Username not found".to_string()))?;

        Ok(CheckUsernameResponse {
            username: user.username,
            account_status: user.account_status,
            full_name: Some(user.full_name),
        })
    }

    pub async fn activate_account(
        &self,
        request: ActivateAccountRequest,
    ) -> AppResult<AuthResponse> {
        Validator::validate_password(&request.password)?;

        if request.password != request.confirm_password {
            return Err(AppError::BadRequest("Passwords do not match".to_string()));
        }

        let user = self
            .user_repo
            .find_by_username(&request.username)
            .await?
            .ok_or_else(|| AppError::NotFound("Username not found".to_string()))?;

        if user.account_status != "pending_activation" {
            return Err(AppError::BadRequest(
                "Account is not pending activation".to_string(),
            ));
        }

        let password_hash = PasswordService::hash_password(&request.password)?;
        let user = self.user_repo.set_password(user.id, password_hash).await?;

        self.activity_log_repo
            .create_log(user.id, "account_activated", None)
            .await?;

        let access_token = self
            .jwt_service
            .generate_token(user.id, &user.username, &user.role)?;

        let refresh_token = self.jwt_service.generate_refresh_token();
        let refresh_token_hash = PasswordService::hash_token(&refresh_token);

        let expires_at = Utc::now().naive_utc() + Duration::days(30);
        self.user_repo
            .create_refresh_token(user.id, refresh_token_hash, None, expires_at)
            .await?;

        Ok(AuthResponse {
            access_token,
            refresh_token,
            token_type: "Bearer".to_string(),
            expires_in: self.jwt_service.expiration,
            user: Self::user_to_response(&user),
        })
    }

    pub async fn login(&self, request: LoginRequest, ip: &str) -> AppResult<AuthResponse> {
        let (is_locked, remaining_seconds) = self
            .login_attempt_repo
            .check_lockout(&request.username, ip)
            .await?;

        if is_locked {
            return Err(AppError::TooManyRequests(remaining_seconds));
        }

        let user = self
            .user_repo
            .find_by_username(&request.username)
            .await?
            .ok_or_else(|| AppError::Unauthorized("Invalid credentials".to_string()))?;

        if user.account_status == "pending_activation" {
            return Err(AppError::Conflict(
                "Account requires activation".to_string(),
            ));
        }

        if user.account_status == "locked" || user.account_status == "deactivated" {
            return Err(AppError::Forbidden("Account is locked".to_string()));
        }

        let password_hash = user
            .password_hash
            .as_ref()
            .ok_or_else(|| AppError::Conflict("Account requires activation".to_string()))?;

        let is_valid = PasswordService::verify_password(&request.password, password_hash)?;
        if !is_valid {
            let (attempt_count, locked_until) = self
                .login_attempt_repo
                .record_failed_attempt(&request.username, ip)
                .await?;

            if locked_until.is_some() {
                return Err(AppError::TooManyRequests(300));
            }

            let attempts_remaining = 5 - attempt_count;
            return Err(AppError::InvalidCredentials(
                "Invalid password".to_string(),
                attempts_remaining,
            ));
        }

        self.login_attempt_repo
            .clear_attempts(&request.username, ip)
            .await?;

        let access_token = self
            .jwt_service
            .generate_token(user.id, &user.username, &user.role)?;

        let refresh_token = self.jwt_service.generate_refresh_token();
        let refresh_token_hash = PasswordService::hash_token(&refresh_token);

        let expires_at = Utc::now().naive_utc() + Duration::days(30);
        self.user_repo
            .create_refresh_token(user.id, refresh_token_hash, request.device_id, expires_at)
            .await?;

        self.activity_log_repo
            .create_log(user.id, "login", None)
            .await?;

        Ok(AuthResponse {
            access_token,
            refresh_token,
            token_type: "Bearer".to_string(),
            expires_in: self.jwt_service.expiration,
            user: Self::user_to_response(&user),
        })
    }

    pub async fn refresh_token(&self, refresh_token: &str) -> AppResult<AuthResponse> {
        let token_hash = PasswordService::hash_token(refresh_token);

        let token = self
            .user_repo
            .find_refresh_token(&token_hash)
            .await?
            .ok_or_else(|| AppError::Unauthorized("Invalid refresh token".to_string()))?;

        if token.expires_at < Utc::now().naive_utc() {
            return Err(AppError::Unauthorized("Refresh token expired".to_string()));
        }

        let user = self
            .user_repo
            .find_by_id(token.user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        if user.account_status == "locked" || user.account_status == "deactivated" {
            return Err(AppError::Forbidden("Account is locked".to_string()));
        }

        self.user_repo.revoke_refresh_token(token.id).await?;

        let access_token = self
            .jwt_service
            .generate_token(user.id, &user.username, &user.role)?;

        let new_refresh_token = self.jwt_service.generate_refresh_token();
        let new_refresh_token_hash = PasswordService::hash_token(&new_refresh_token);

        let expires_at = Utc::now().naive_utc() + Duration::days(30);
        self.user_repo
            .create_refresh_token(user.id, new_refresh_token_hash, token.device_id, expires_at)
            .await?;

        Ok(AuthResponse {
            access_token,
            refresh_token: new_refresh_token,
            token_type: "Bearer".to_string(),
            expires_in: self.jwt_service.expiration,
            user: Self::user_to_response(&user),
        })
    }

    pub async fn get_current_user(&self, user_id: Uuid) -> AppResult<crate::schema::auth_schema::UserResponse> {
        let user = self
            .user_repo
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        Ok(Self::user_to_response(&user))
    }

    pub async fn logout(&self, refresh_token: &str) -> AppResult<()> {
        let token_hash = PasswordService::hash_token(refresh_token);

        if let Some(token) = self.user_repo.find_refresh_token(&token_hash).await? {
            self.user_repo.revoke_refresh_token(token.id).await?;
        }

        Ok(())
    }
}