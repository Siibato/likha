use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::auth_schema::{CreateAccountRequest, UserResponse};
use crate::utils::validators::Validator;

impl crate::services::auth::AuthService {
    pub async fn create_account(
        &self,
        request: CreateAccountRequest,
        created_by: Uuid,
        client_id: Option<Uuid>,
    ) -> AppResult<UserResponse> {
        Validator::validate_username(&request.username)?;
        Validator::validate_role(&request.role)?;

        let existing = self.user_repo.find_by_username(&request.username).await?;
        if existing.is_some() {
            return Err(AppError::Conflict("Username already taken".to_string()));
        }

        let user = self.user_repo
            .create_account(request.username, request.full_name, request.role, client_id)
            .await?;

        let _ = self.activity_log_repo
            .create_log(created_by, "account_created", Some(format!("Created account '{}'", user.username)))
            .await;

        Ok(Self::user_to_response(&user))
    }
}
