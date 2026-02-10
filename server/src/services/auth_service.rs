use chrono::{Duration, Utc};
use sea_orm::DatabaseConnection;
use uuid::Uuid;

use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::db::repositories::user_repository::UserRepository;
use crate::schema::admin_schema::{AccountListResponse, ActivityLogListResponse, ActivityLogResponse};
use crate::schema::auth_schema::{
    ActivateAccountRequest, AuthResponse, CheckUsernameRequest, CheckUsernameResponse,
    CreateAccountRequest, LockAccountRequest, LoginRequest, ResetAccountRequest,
    UpdateAccountRequest, UserResponse,
};
use crate::utils::error::{AppError, AppResult};
use crate::utils::jwt::JwtService;
use crate::utils::password::PasswordService;
use crate::utils::validators::Validator;

pub struct AuthService {
    user_repo: UserRepository,
    activity_log_repo: ActivityLogRepository,
    jwt_service: JwtService,
}

impl AuthService {
    pub fn new(
        db: DatabaseConnection,
        jwt_secret: String,
        jwt_expiration: i64,
    ) -> Self {
        Self {
            user_repo: UserRepository::new(db.clone()),
            activity_log_repo: ActivityLogRepository::new(db),
            jwt_service: JwtService::new(jwt_secret, jwt_expiration),
        }
    }

    fn user_to_response(user: &::entity::users::Model) -> UserResponse {
        UserResponse {
            id: user.id,
            username: user.username.clone(),
            full_name: user.full_name.clone(),
            role: user.role.clone(),
            account_status: user.account_status.clone(),
            is_active: user.is_active,
            activated_at: user.activated_at.map(|dt| dt.to_string()),
            created_at: user.created_at.to_string(),
        }
    }

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
                Some(admin_id),
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

        Ok(Self::user_to_response(&user))
    }

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
            .create_log(user.id, "account_activated", Some(user.id), None)
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

    pub async fn login(&self, request: LoginRequest) -> AppResult<AuthResponse> {
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

        if user.account_status == "locked" || !user.is_active {
            return Err(AppError::Forbidden("Account is locked".to_string()));
        }

        let password_hash = user
            .password_hash
            .as_ref()
            .ok_or_else(|| AppError::Conflict("Account requires activation".to_string()))?;

        let is_valid = PasswordService::verify_password(&request.password, password_hash)?;
        if !is_valid {
            return Err(AppError::Unauthorized("Invalid credentials".to_string()));
        }

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
            .create_log(user.id, "login", Some(user.id), None)
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

        if !user.is_active || user.account_status == "locked" {
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

    pub async fn get_current_user(&self, user_id: Uuid) -> AppResult<UserResponse> {
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

    // ===== Admin methods =====

    pub async fn get_all_accounts(&self) -> AppResult<AccountListResponse> {
        let users = self.user_repo.find_all_users().await?;
        let total = users.len();
        let accounts = users.iter().map(Self::user_to_response).collect();

        Ok(AccountListResponse { accounts, total })
    }

    pub async fn update_account(
        &self,
        user_id: Uuid,
        request: UpdateAccountRequest,
        admin_id: Uuid,
    ) -> AppResult<UserResponse> {
        if request.username.is_none() && request.full_name.is_none() {
            return Err(AppError::BadRequest("No fields to update".to_string()));
        }

        if let Some(ref username) = request.username {
            Validator::validate_username(username)?;
            // Check if username is taken by another user
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

        let user = self
            .user_repo
            .update_account(user_id, request.username, request.full_name.map(|n| n.trim().to_string()))
            .await?;

        self.activity_log_repo
            .create_log(
                user.id,
                "account_updated",
                Some(admin_id),
                Some("Account details updated".to_string()),
            )
            .await?;

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

        Ok(Self::user_to_response(&user))
    }

    pub async fn lock_account(
        &self,
        request: LockAccountRequest,
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
            // Restore to activated if they had a password, otherwise pending_activation
            if user.password_hash.is_some() {
                ("activated", "account_unlocked")
            } else {
                ("pending_activation", "account_unlocked")
            }
        };

        let user = self.user_repo.update_account_status(user.id, status).await?;

        self.activity_log_repo
            .create_log(user.id, action, Some(admin_id), None)
            .await?;

        Ok(Self::user_to_response(&user))
    }

    pub async fn get_activity_logs(
        &self,
        user_id: Uuid,
    ) -> AppResult<ActivityLogListResponse> {
        // Verify user exists
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
