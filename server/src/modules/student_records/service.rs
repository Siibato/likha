use sea_orm::DatabaseConnection;
use std::sync::Arc;

use crate::modules::class::repository::ClassRepository;
use crate::modules::grading::service::GradeComputationService;
use crate::modules::student_records::repository::StudentRecordsRepository;

pub struct StudentRecordsService {
    pub repo: StudentRecordsRepository,
    pub class_repo: ClassRepository,
    pub grade_service: Arc<GradeComputationService>,
    pub db: DatabaseConnection,
}

impl StudentRecordsService {
    pub fn new(db: DatabaseConnection, grade_service: Arc<GradeComputationService>) -> Self {
        Self {
            repo: StudentRecordsRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            grade_service,
            db,
        }
    }
}
