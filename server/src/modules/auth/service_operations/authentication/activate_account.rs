use chrono::{Duration, Utc};
use crate::utils::error::{AppError, AppResult};
use crate::modules::auth::schema::{ActivateAccountRequest, AuthResponse};
use crate::utils::password::PasswordService;
use crate::utils::validators::Validator;
use crate::db::repositories::user_repository::UserRepository;
use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::utils::jwt::JwtService;
use crate::modules::auth::service_operations::helpers::user_to_response;

pub async fn activate_account(
    user_repo: &UserRepository,
    activity_log_repo: &ActivityLogRepository,
    jwt_service: &JwtService,
    request: ActivateAccountRequest,
) -> AppResult<AuthResponse> {
    Validator::validate_password(&request.password)?;

    if request.password != request.confirm_password {
        return Err(AppError::BadRequest("Passwords do not match".to_string()));
    }

    let user = user_repo
        .find_by_username(&request.username)
        .await?
        .ok_or_else(|| AppError::NotFound("Username does not exist".to_string()))?;

    if user.account_status != "pending_activation" {
        return Err(AppError::BadRequest(
            "Account is not pending activation".to_string(),
        ));
    }

    let password_hash = PasswordService::hash_password(&request.password)?;
    let user = user_repo.set_password(user.id, password_hash).await?;

    activity_log_repo
        .create_log(user.id, "account_activated", None)
        .await?;

    let access_token = jwt_service.generate_token(user.id, &user.username, &user.role)?;

    let refresh_token = jwt_service.generate_refresh_token();
    let refresh_token_hash = PasswordService::hash_token(&refresh_token);

    let expires_at = Utc::now().naive_utc() + Duration::days(30);
    user_repo
        .create_refresh_token(user.id, refresh_token_hash, None, expires_at)
        .await?;

    Ok(AuthResponse {
        access_token,
        refresh_token,
        token_type: "Bearer".to_string(),
        expires_in: jwt_service.expiration,
        user: user_to_response(&user),
    })
}
