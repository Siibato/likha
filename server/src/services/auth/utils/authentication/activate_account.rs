use chrono::{Duration, Utc};
use crate::utils::error::{AppError, AppResult};
use crate::schema::auth_schema::{ActivateAccountRequest, AuthResponse};
use crate::utils::password::PasswordService;
use crate::utils::validators::Validator;

impl crate::services::auth::AuthService {
    pub async fn activate_account(
        &self,
        request: ActivateAccountRequest,
    ) -> AppResult<AuthResponse> {
        Validator::validate_password(&request.password)?;

        if request.password != request.confirm_password {
            return Err(AppError::BadRequest("Passwords do not match".to_string()));
        }

        let user = self.user_repo
            .find_by_username(&request.username)
            .await?
            .ok_or_else(|| AppError::NotFound("Username does not exist".to_string()))?;

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
}
