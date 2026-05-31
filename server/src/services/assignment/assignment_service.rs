use sea_orm::DatabaseConnection;
use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::db::repositories::assignment_repository::AssignmentRepository;
use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::grade_computation_repository::GradeComputationRepository;

pub struct AssignmentService {
    pub assignment_repo: AssignmentRepository,
    pub class_repo: ClassRepository,
    pub activity_log_repo: ActivityLogRepository,
    pub file_storage_path: String,
    pub file_encryption_key: [u8; 32],
    pub grade_computation_repo: GradeComputationRepository,
}

impl AssignmentService {
    pub fn new(db: DatabaseConnection, file_storage_path: String, file_encryption_key: [u8; 32]) -> Self {
        Self {
            assignment_repo: AssignmentRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            activity_log_repo: ActivityLogRepository::new(db.clone()),
            grade_computation_repo: GradeComputationRepository::new(db.clone()),
            file_storage_path,
            file_encryption_key,
        }
    }
}