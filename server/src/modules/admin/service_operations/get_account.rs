use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::auth::schema::UserResponse;
use crate::db::repositories::user_repository::UserRepository;
use crate::modules::auth::helpers::user_to_response;

pub async fn get_account(
    user_repo: &UserRepository,
    user_id: Uuid,
) -> AppResult<UserResponse> {
    let user = user_repo.find_by_id(user_id).await?
        .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

    Ok(user_to_response(&user))
}
