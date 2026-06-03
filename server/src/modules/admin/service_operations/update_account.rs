use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::auth::schema::UserResponse;
use crate::modules::admin::schema::UpdateAccountRequest;
use crate::modules::auth::UserRepository;
use crate::modules::auth::helpers::user_to_response;

pub async fn update_account(
    user_repo: &UserRepository,
    user_id: Uuid,
    request: UpdateAccountRequest,
    _admin_id: Uuid,
) -> AppResult<UserResponse> {
    let _user = user_repo.find_by_id(user_id).await?
        .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

    let updated = user_repo.update_account(user_id, request.full_name, request.role).await?;
    Ok(user_to_response(&updated))
}
