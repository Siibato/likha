use sea_orm::DatabaseConnection;
use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::user_repository::UserRepository;

pub struct ClassService {
    pub class_repo: ClassRepository,
    pub user_repo: UserRepository,
}

impl ClassService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            class_repo: ClassRepository::new(db.clone()),
            user_repo: UserRepository::new(db),
        }
    }
}