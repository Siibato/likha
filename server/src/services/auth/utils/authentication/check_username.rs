use crate::utils::error::{AppError, AppResult};
use crate::schema::auth_schema::{CheckUsernameRequest, CheckUsernameResponse};

impl crate::services::auth::AuthService {
    pub async fn check_username(
        &self,
        request: CheckUsernameRequest,
    ) -> AppResult<CheckUsernameResponse> {
        let user = self.user_repo
            .find_by_username(&request.username)
            .await?
            .ok_or_else(|| AppError::NotFound("Username does not exist".to_string()))?;

        Ok(CheckUsernameResponse {
            username: user.username,
            account_status: user.account_status,
            full_name: Some(user.full_name),
        })
    }
}
