use sea_orm::DatabaseConnection;
use crate::db::repositories::user_repository::UserRepository;
use crate::db::repositories::activity_log_repository::ActivityLogRepository;

pub struct AdminRepository {
    pub user_repo: UserRepository,
    pub activity_log_repo: ActivityLogRepository,
}

impl AdminRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            user_repo: UserRepository::new(db.clone()),
            activity_log_repo: ActivityLogRepository::new(db),
        }
    }
}
