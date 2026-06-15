use crate::utils::AppResult;
use crate::modules::auth::schema::UserResponse;
use crate::modules::admin::schema::AccountListResponse;
use crate::modules::auth::UserRepository;
use crate::modules::auth::helpers::user_to_response;

pub async fn get_all_accounts(
    user_repo: &UserRepository,
) -> AppResult<AccountListResponse> {
    let users = user_repo.find_all_users().await?;
    let accounts: Vec<UserResponse> = users.iter().map(user_to_response).collect();
    Ok(AccountListResponse { accounts })
}
