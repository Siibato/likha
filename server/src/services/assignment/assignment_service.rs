use sea_orm::DatabaseConnection;
use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::db::repositories::assignment_repository::AssignmentRepository;
use crate::db::repositories::class_repository::ClassRepository;

pub struct AssignmentService {
    pub assignment_repo: AssignmentRepository,
    pub class_repo: ClassRepository,
    pub activity_log_repo: ActivityLogRepository,
    pub file_storage_path: String,
    pub db: DatabaseConnection,
}

impl AssignmentService {
    pub fn new(db: DatabaseConnection, file_storage_path: String) -> Self {
        let db_clone = db.clone();
        Self {
            assignment_repo: AssignmentRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            activity_log_repo: ActivityLogRepository::new(db),
            file_storage_path,
            db: db_clone,
        }
    }
}