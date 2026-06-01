use chrono::{Duration, Utc};
use crate::utils::error::{AppError, AppResult};
use crate::modules::auth::schema::{AuthResponse, LoginRequest};
use crate::utils::password::PasswordService;
use crate::db::repositories::user_repository::UserRepository;
use crate::db::repositories::login_attempt_repository::LoginAttemptRepository;
use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::utils::jwt::JwtService;
use crate::modules::auth::helpers::user_to_response;

pub async fn login(
    user_repo: &UserRepository,
    login_attempt_repo: &LoginAttemptRepository,
    activity_log_repo: &ActivityLogRepository,
    jwt_service: &JwtService,
    request: LoginRequest,
    ip: &str,
) -> AppResult<AuthResponse> {
    let (is_locked, remaining_seconds, _lockout_level) = login_attempt_repo
        .check_lockout(&request.username, ip)
        .await?;

    if is_locked {
        return Err(AppError::TooManyRequests(remaining_seconds));
    }

    let user = user_repo
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
        let (attempts_remaining, locked_until, _lockout_level) = login_attempt_repo
            .record_failed_attempt(&request.username, ip)
            .await?;

        if let Some(lock_time) = locked_until {
            let remaining_seconds = (lock_time - Utc::now().naive_utc()).num_seconds();
            return Err(AppError::TooManyRequests(remaining_seconds));
        }

        return Err(AppError::InvalidCredentials(
            "Invalid password".to_string(),
            attempts_remaining,
        ));
    }

    login_attempt_repo
        .clear_attempts(&request.username, ip)
        .await?;

    let access_token = jwt_service.generate_token(user.id, &user.username, &user.role)?;

    let refresh_token = jwt_service.generate_refresh_token();
    let refresh_token_hash = PasswordService::hash_token(&refresh_token);

    let expires_at = Utc::now().naive_utc() + Duration::days(30);
    user_repo
        .create_refresh_token(user.id, refresh_token_hash, request.device_id, expires_at)
        .await?;

    activity_log_repo
        .create_log(user.id, "login", None)
        .await?;

    Ok(AuthResponse {
        access_token,
        refresh_token,
        token_type: "Bearer".to_string(),
        expires_in: jwt_service.expiration,
        user: user_to_response(&user),
    })
}
