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
    pub db: DatabaseConnection,
}

impl AuthService {
    pub fn new(
        db: DatabaseConnection,
        jwt_secret: String,
        jwt_expiration: i64,
    ) -> Self {
        let db_clone = db.clone();
        Self {
            user_repo: UserRepository::new(db.clone()),
            activity_log_repo: ActivityLogRepository::new(db.clone()),
            login_attempt_repo: LoginAttemptRepository::new(db.clone()),
            jwt_service: JwtService::new(jwt_secret, jwt_expiration),
            db: db_clone,
        }
    }
}