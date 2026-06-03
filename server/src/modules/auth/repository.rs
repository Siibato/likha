use sea_orm::DatabaseConnection;

use crate::modules::admin::ActivityLogRepository;
use crate::modules::auth::LoginAttemptRepository;
use crate::modules::auth::UserRepository;

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
