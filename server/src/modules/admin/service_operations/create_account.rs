use crate::modules::admin::schema::CreateAccountRequest;
use crate::modules::admin::service_operations::upsert_account_details::upsert_account_details;
use crate::modules::admin::ActivityLogRepository;
use crate::modules::auth::helpers::user_to_response;
use crate::modules::auth::schema::UserResponse;
use crate::modules::auth::UserRepository;
use crate::utils::error::{AppError, AppResult};
use crate::utils::validators::Validator;
use sea_orm::DatabaseConnection;
use uuid::Uuid;

pub async fn create_account(
    db: &DatabaseConnection,
    user_repo: &UserRepository,
    activity_log_repo: &ActivityLogRepository,
    request: CreateAccountRequest,
    created_by: Uuid,
    client_id: Option<Uuid>,
) -> AppResult<UserResponse> {
    Validator::validate_username(&request.username)?;
    Validator::validate_role(&request.role)?;

    let existing = user_repo.find_by_username(&request.username).await?;
    if existing.is_some() {
        return Err(AppError::Conflict("Username already taken".to_string()));
    }

    let user = user_repo
        .create_account(
            request.username,
            request.first_name,
            request.last_name,
            request.role,
            client_id,
        )
        .await?;

    if request.learner_details.is_some() || request.teacher_details.is_some() {
        let _ = upsert_account_details(
            db,
            user.id,
            &user.role,
            request.learner_details,
            request.teacher_details,
        )
        .await;
    }

    let _ = activity_log_repo
        .create_log(
            created_by,
            "account_created",
            Some(format!("Created account '{}'", user.username)),
        )
        .await;

    Ok(user_to_response(&user))
}
