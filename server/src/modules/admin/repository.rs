use sea_orm::DatabaseConnection;
use crate::modules::auth::UserRepository;
use crate::modules::admin::ActivityLogRepository;

pub struct AdminRepository {
    pub user_repo: UserRepository,
    pub activity_log_repo: ActivityLogRepository,
    pub db: DatabaseConnection,
}

impl AdminRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            user_repo: UserRepository::new(db.clone()),
            activity_log_repo: ActivityLogRepository::new(db.clone()),
            db,
        }
    }
}
