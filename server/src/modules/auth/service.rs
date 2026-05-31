use sea_orm::DatabaseConnection;

use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::db::repositories::login_attempt_repository::LoginAttemptRepository;
use crate::db::repositories::user_repository::UserRepository;
use crate::utils::jwt::JwtService;

pub struct AuthService {
    pub user_repo: UserRepository,
    pub activity_log_repo: ActivityLogRepository,
    pub login_attempt_repo: LoginAttemptRepository,
    pub jwt_service: JwtService,
}

impl AuthService {
    pub fn new(
        db: DatabaseConnection,
        jwt_secret: String,
        jwt_expiration: i64,
    ) -> Self {
        Self {
            user_repo: UserRepository::new(db.clone()),
            activity_log_repo: ActivityLogRepository::new(db.clone()),
            login_attempt_repo: LoginAttemptRepository::new(db),
            jwt_service: JwtService::new(jwt_secret, jwt_expiration),
        }
    }

    // Authentication operations
    pub async fn check_username(&self, request: crate::modules::auth::schema::CheckUsernameRequest) -> crate::utils::AppResult<crate::modules::auth::schema::CheckUsernameResponse> {
        crate::modules::auth::service_operations::authentication::check_username(&self.user_repo, request).await
    }

    pub async fn activate_account(&self, request: crate::modules::auth::schema::ActivateAccountRequest) -> crate::utils::AppResult<crate::modules::auth::schema::AuthResponse> {
        crate::modules::auth::service_operations::authentication::activate_account(&self.user_repo, &self.activity_log_repo, &self.jwt_service, request).await
    }

    pub async fn login(&self, request: crate::modules::auth::schema::LoginRequest, ip: &str) -> crate::utils::AppResult<crate::modules::auth::schema::AuthResponse> {
        crate::modules::auth::service_operations::authentication::login(&self.user_repo, &self.login_attempt_repo, &self.activity_log_repo, &self.jwt_service, request, ip).await
    }

    pub async fn refresh_token(&self, refresh_token: &str) -> crate::utils::AppResult<crate::modules::auth::schema::AuthResponse> {
        crate::modules::auth::service_operations::authentication::refresh_token(&self.user_repo, &self.jwt_service, refresh_token).await
    }

    pub async fn get_current_user(&self, user_id: uuid::Uuid) -> crate::utils::AppResult<crate::modules::auth::schema::UserResponse> {
        crate::modules::auth::service_operations::authentication::get_current_user(&self.user_repo, user_id).await
    }

    pub async fn logout(&self, refresh_token: &str) -> crate::utils::AppResult<()> {
        crate::modules::auth::service_operations::authentication::logout(&self.user_repo, refresh_token).await
    }

    // Account operations
    pub async fn create_account(&self, request: crate::modules::auth::schema::CreateAccountRequest, created_by: uuid::Uuid, client_id: Option<uuid::Uuid>) -> crate::utils::AppResult<crate::modules::auth::schema::UserResponse> {
        crate::modules::auth::service_operations::account::create_account(&self.user_repo, &self.activity_log_repo, request, created_by, client_id).await
    }

    pub async fn update_account(&self, user_id: uuid::Uuid, request: crate::modules::auth::schema::UpdateAccountRequest, admin_id: uuid::Uuid) -> crate::utils::AppResult<crate::modules::auth::schema::UserResponse> {
        crate::modules::auth::service_operations::account::update_account(&self.user_repo, user_id, request, admin_id).await
    }

    pub async fn reset_account(&self, request: crate::modules::auth::schema::ResetAccountRequest, admin_id: uuid::Uuid) -> crate::utils::AppResult<crate::modules::auth::schema::UserResponse> {
        crate::modules::auth::service_operations::account::reset_account(&self.user_repo, &self.activity_log_repo, request, admin_id).await
    }

    pub async fn get_account(&self, user_id: uuid::Uuid) -> crate::utils::AppResult<crate::modules::auth::schema::UserResponse> {
        crate::modules::auth::service_operations::account::get_account(&self.user_repo, user_id).await
    }

    // Admin operations
    pub async fn get_all_accounts(&self) -> crate::utils::AppResult<Vec<crate::modules::auth::schema::UserResponse>> {
        crate::modules::auth::service_operations::admin::get_all_accounts(&self.user_repo).await
    }

    pub async fn lock_account(&self, request: crate::modules::auth::schema::LockAccountRequest, admin_id: uuid::Uuid) -> crate::utils::AppResult<crate::modules::auth::schema::UserResponse> {
        crate::modules::auth::service_operations::admin::lock_account(&self.user_repo, &self.activity_log_repo, request, admin_id).await
    }

    pub async fn delete_account(&self, user_id: uuid::Uuid, admin_id: uuid::Uuid) -> crate::utils::AppResult<()> {
        crate::modules::auth::service_operations::admin::delete_account(&self.user_repo, &self.activity_log_repo, user_id, admin_id).await
    }

    pub async fn get_activity_logs(&self, user_id: uuid::Uuid) -> crate::utils::AppResult<Vec<::entity::activity_logs::Model>> {
        crate::modules::auth::service_operations::admin::get_activity_logs(&self.activity_log_repo, user_id).await
    }

    pub async fn search_students(&self, query: &str) -> crate::utils::AppResult<Vec<crate::modules::auth::schema::UserResponse>> {
        crate::modules::auth::service_operations::admin::search_students(&self.user_repo, query).await
    }
}
