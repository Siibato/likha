use crate::utils::AppResult;
use crate::schema::auth_schema::UserResponse;

impl crate::services::auth::AuthService {
    pub async fn get_all_accounts(&self) -> AppResult<Vec<UserResponse>> {
        let users = self.user_repo.find_all_users().await?;
        Ok(users.iter().map(Self::user_to_response).collect())
    }
}
