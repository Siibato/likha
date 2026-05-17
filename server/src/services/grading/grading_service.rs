use sea_orm::DatabaseConnection;
use crate::db::repositories::assessment_repository::AssessmentRepository;

pub struct GradingService {
    pub assessment_repo: AssessmentRepository,
    pub db: DatabaseConnection,
}

impl GradingService {
    pub fn new(db: DatabaseConnection) -> Self {
        let db_clone = db.clone();
        Self {
            assessment_repo: AssessmentRepository::new(db.clone()),
            db: db_clone,
        }
    }
}