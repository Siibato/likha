use sea_orm::DatabaseConnection;

use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::db::repositories::login_attempt_repository::LoginAttemptRepository;
use crate::db::repositories::user_repository::UserRepository;

pub struct AuthRepository {
    pub user_repo: UserRepository,
    pub activity_log_repo: ActivityLogRepository,
    pub login_attempt_repo: LoginAttemptRepository,
}

impl AuthRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            user_repo: UserRepository::new(db.clone()),
            activity_log_repo: ActivityLogRepository::new(db.clone()),
            login_attempt_repo: LoginAttemptRepository::new(db),
        }
    }
}
