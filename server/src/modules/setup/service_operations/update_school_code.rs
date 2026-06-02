use sea_orm::DatabaseConnection;
use uuid::Uuid;

use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::modules::setup::repository::SetupRepository;
use crate::utils::{AppError, AppResult};

pub async fn update_school_code(
    repo: &SetupRepository,
    activity_log_repo: &ActivityLogRepository,
    new_code: String,
    admin_id: Uuid,
) -> AppResult<()> {
    let trimmed = new_code.trim().to_uppercase();
    if trimmed.len() != 6 || !trimmed.chars().all(|c| c.is_ascii_alphanumeric()) {
        return Err(AppError::BadRequest(
            "Code must be exactly 6 alphanumeric characters".to_string(),
        ));
    }

    repo.update_settings(Some(trimmed.clone()), None, None, None, None)
        .await?;

    // Log the school code change
    let _ = activity_log_repo
        .create_log(
            admin_id,
            "school_code_updated",
            Some(format!("School code updated to: {}", trimmed)),
        )
        .await;

    Ok(())
}
