use sea_orm::DatabaseConnection;
use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::db::repositories::assignment_repository::AssignmentRepository;
use crate::db::repositories::change_log_repository::ChangeLogRepository;
use crate::db::repositories::class_repository::ClassRepository;

pub struct AssignmentService {
    pub assignment_repo: AssignmentRepository,
    pub class_repo: ClassRepository,
    pub activity_log_repo: ActivityLogRepository,
    pub change_log_repo: ChangeLogRepository,
}

impl AssignmentService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            assignment_repo: AssignmentRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            activity_log_repo: ActivityLogRepository::new(db.clone()),
            change_log_repo: ChangeLogRepository::new(db),
        }
    }
}