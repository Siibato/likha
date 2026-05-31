use chrono::{Duration, Utc};
use crate::utils::error::{AppError, AppResult};
use crate::schema::auth_schema::AuthResponse;
use crate::utils::password::PasswordService;

impl crate::services::auth::AuthService {
    pub async fn refresh_token(&self, refresh_token: &str) -> AppResult<AuthResponse> {
        let token_hash = PasswordService::hash_token(refresh_token);

        let token = self.user_repo
            .find_refresh_token(&token_hash)
            .await?
            .ok_or_else(|| AppError::Unauthorized("Invalid refresh token".to_string()))?;

        if token.expires_at < Utc::now().naive_utc() {
            return Err(AppError::Unauthorized("Refresh token expired".to_string()));
        }

        let user = self.user_repo
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
}
