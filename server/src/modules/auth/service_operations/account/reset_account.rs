use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::auth::schema::{ResetAccountRequest, UserResponse};
use crate::db::repositories::user_repository::UserRepository;
use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::modules::auth::service_operations::helpers::user_to_response;

pub async fn reset_account(
    user_repo: &UserRepository,
    activity_log_repo: &ActivityLogRepository,
    request: ResetAccountRequest,
    admin_id: Uuid,
) -> AppResult<UserResponse> {
    let user = user_repo.find_by_id(request.user_id).await?
        .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

    user_repo.clear_password(request.user_id).await?;
    let updated = user_repo.update_account_status(request.user_id, "pending_activation").await?;

    let _ = activity_log_repo
        .create_log(
            admin_id,
            "account_reset",
            Some(format!("Reset account '{}'", user.username)),
        )
        .await;

    Ok(user_to_response(&updated))
}
