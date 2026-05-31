use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::auth_schema::{UpdateAccountRequest, UserResponse};

impl crate::services::auth::AuthService {
    pub async fn update_account(
        &self,
        user_id: Uuid,
        request: UpdateAccountRequest,
        _admin_id: Uuid,
    ) -> AppResult<UserResponse> {
        let _user = self.user_repo.find_by_id(user_id).await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        let updated = self.user_repo.update_account(user_id, request.full_name, request.role).await?;
        Ok(Self::user_to_response(&updated))
    }
}
