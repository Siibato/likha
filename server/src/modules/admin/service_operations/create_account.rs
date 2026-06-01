use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::auth::schema::UserResponse;
use crate::modules::admin::schema::CreateAccountRequest;
use crate::utils::validators::Validator;
use crate::db::repositories::user_repository::UserRepository;
use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::modules::auth::helpers::user_to_response;

pub async fn create_account(
    user_repo: &UserRepository,
    activity_log_repo: &ActivityLogRepository,
    request: CreateAccountRequest,
    created_by: Uuid,
    client_id: Option<Uuid>,
) -> AppResult<UserResponse> {
    Validator::validate_username(&request.username)?;
    Validator::validate_role(&request.role)?;

    let existing = user_repo.find_by_username(&request.username).await?;
    if existing.is_some() {
        return Err(AppError::Conflict("Username already taken".to_string()));
    }

    let user = user_repo
        .create_account(request.username, request.full_name, request.role, client_id)
        .await?;

    let _ = activity_log_repo
        .create_log(created_by, "account_created", Some(format!("Created account '{}'", user.username)))
        .await;

    Ok(user_to_response(&user))
}
