use crate::modules::auth::UserRepository;
use crate::utils::password::PasswordService;
use crate::utils::AppResult;

pub async fn logout(user_repo: &UserRepository, refresh_token: &str) -> AppResult<()> {
    let token_hash = PasswordService::hash_token(refresh_token);

    if let Some(token) = user_repo.find_refresh_token(&token_hash).await? {
        user_repo.revoke_refresh_token(token.id).await?;
    }

    Ok(())
}
