use sea_orm::DatabaseConnection;
use crate::modules::assessment::repository::AssessmentRepository;
use crate::modules::class::repository::ClassRepository;
use crate::modules::grading::repository::GradeComputationRepository;
use crate::db::repositories::user_repository::UserRepository;

pub struct AssessmentService {
    pub assessment_repo: AssessmentRepository,
    pub class_repo: ClassRepository,
    pub user_repo: UserRepository,
    pub grade_computation_repo: GradeComputationRepository,
}

impl AssessmentService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            assessment_repo: AssessmentRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            user_repo: UserRepository::new(db.clone()),
            grade_computation_repo: GradeComputationRepository::new(db),
        }
    }
}
