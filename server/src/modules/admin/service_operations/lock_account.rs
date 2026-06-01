use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::auth::schema::UserResponse;
use crate::modules::admin::schema::LockAccountRequest;
use crate::db::repositories::user_repository::UserRepository;
use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::modules::auth::helpers::user_to_response;

pub async fn lock_account(
    user_repo: &UserRepository,
    activity_log_repo: &ActivityLogRepository,
    request: LockAccountRequest,
    admin_id: Uuid,
) -> AppResult<UserResponse> {
    let user = user_repo.find_by_id(request.user_id).await?
        .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

    let new_status = if request.locked { "locked" } else { "active" };

    let updated = user_repo.update_account_status(request.user_id, new_status).await?;

    let action = if request.locked { "account_locked" } else { "account_unlocked" };
    let _ = activity_log_repo
        .create_log(
            admin_id,
            action,
            Some(format!("{} account '{}'", action, user.username)),
        )
        .await;

    Ok(user_to_response(&updated))
}
