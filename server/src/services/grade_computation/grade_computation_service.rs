use sea_orm::DatabaseConnection;

use crate::modules::class::repository::ClassRepository;
use crate::db::repositories::grade_computation_repository::GradeComputationRepository;

pub struct GradeComputationService {
    pub repo: GradeComputationRepository,
    pub class_repo: ClassRepository,
    pub db: DatabaseConnection,
}

impl GradeComputationService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            repo: GradeComputationRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            db,
        }
    }
}
