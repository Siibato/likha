use crate::utils::AppResult;
use crate::modules::auth::schema::UserResponse;
use crate::db::repositories::user_repository::UserRepository;
use crate::modules::auth::service_operations::helpers::user_to_response;

pub async fn search_students(
    user_repo: &UserRepository,
    query: &str,
) -> AppResult<Vec<UserResponse>> {
    let users = user_repo.search_students(query).await?;
    Ok(users.iter().map(user_to_response).collect())
}
