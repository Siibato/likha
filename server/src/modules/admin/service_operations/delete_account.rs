use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::auth::UserRepository;
use crate::modules::admin::ActivityLogRepository;

pub async fn delete_account(
    user_repo: &UserRepository,
    activity_log_repo: &ActivityLogRepository,
    user_id: Uuid,
    admin_id: Uuid,
) -> AppResult<()> {
    let user = user_repo.find_by_id(user_id).await?
        .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

    user_repo.soft_delete(user_id).await?;

    let _ = activity_log_repo
        .create_log(
            admin_id,
            "account_deleted",
            Some(format!("Deleted account '{}'", user.username)),
        )
        .await;

    Ok(())
}
