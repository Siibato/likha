use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::auth_schema::UserResponse;

impl crate::services::auth::AuthService {
    pub async fn get_account(&self, user_id: Uuid) -> AppResult<UserResponse> {
        let user = self.user_repo.find_by_id(user_id).await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        Ok(Self::user_to_response(&user))
    }
}
