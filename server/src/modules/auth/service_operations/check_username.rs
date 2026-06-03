use crate::utils::error::{AppError, AppResult};
use crate::modules::auth::schema::{CheckUsernameRequest, CheckUsernameResponse};
use crate::modules::auth::UserRepository;

pub async fn check_username(
    user_repo: &UserRepository,
    request: CheckUsernameRequest,
) -> AppResult<CheckUsernameResponse> {
    let user = user_repo
        .find_by_username(&request.username)
        .await?
        .ok_or_else(|| AppError::NotFound("Username does not exist".to_string()))?;

    Ok(CheckUsernameResponse {
        username: user.username,
        account_status: user.account_status,
        full_name: Some(user.full_name),
    })
}
