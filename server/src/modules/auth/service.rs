use sea_orm::DatabaseConnection;

use crate::modules::admin::ActivityLogRepository;
use crate::modules::auth::LoginAttemptRepository;
use crate::modules::auth::UserRepository;
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
        crate::modules::auth::service_operations::check_username(&self.user_repo, request).await
    }

    pub async fn activate_account(&self, request: crate::modules::auth::schema::ActivateAccountRequest) -> crate::utils::AppResult<crate::modules::auth::schema::AuthResponse> {
        crate::modules::auth::service_operations::activate_account(&self.user_repo, &self.activity_log_repo, &self.jwt_service, request).await
    }

    pub async fn login(&self, request: crate::modules::auth::schema::LoginRequest, ip: &str) -> crate::utils::AppResult<crate::modules::auth::schema::AuthResponse> {
        crate::modules::auth::service_operations::login(&self.user_repo, &self.login_attempt_repo, &self.activity_log_repo, &self.jwt_service, request, ip).await
    }

    pub async fn refresh_token(&self, refresh_token: &str) -> crate::utils::AppResult<crate::modules::auth::schema::AuthResponse> {
        crate::modules::auth::service_operations::refresh_token(&self.user_repo, &self.jwt_service, refresh_token).await
    }

    pub async fn get_current_user(&self, user_id: uuid::Uuid) -> crate::utils::AppResult<crate::modules::auth::schema::UserResponse> {
        crate::modules::auth::service_operations::get_current_user(&self.user_repo, user_id).await
    }

    pub async fn logout(&self, refresh_token: &str) -> crate::utils::AppResult<()> {
        crate::modules::auth::service_operations::logout(&self.user_repo, refresh_token).await
    }
}
