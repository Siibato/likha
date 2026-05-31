use crate::utils::AppResult;
use crate::utils::password::PasswordService;

impl crate::services::auth::AuthService {
    pub async fn logout(&self, refresh_token: &str) -> AppResult<()> {
        let token_hash = PasswordService::hash_token(refresh_token);

        if let Some(token) = self.user_repo.find_refresh_token(&token_hash).await? {
            self.user_repo.revoke_refresh_token(token.id).await?;
        }

        Ok(())
    }
}
