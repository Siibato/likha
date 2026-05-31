use crate::utils::AppResult;
use crate::schema::auth_schema::UserResponse;

impl crate::services::auth::AuthService {
    pub async fn search_students(&self, query: &str) -> AppResult<Vec<UserResponse>> {
        let users = self.user_repo.search_students(query).await?;
        Ok(users.iter().map(Self::user_to_response).collect())
    }
}
