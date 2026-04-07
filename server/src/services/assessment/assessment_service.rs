use sea_orm::DatabaseConnection;
use crate::db::repositories::assessment_repository::AssessmentRepository;
use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::submission_repository::SubmissionRepository;
use crate::db::repositories::user_repository::UserRepository;
pub struct AssessmentService {
    pub assessment_repo: AssessmentRepository,
    pub submission_repo: SubmissionRepository,
    pub class_repo: ClassRepository,
    pub user_repo: UserRepository,
    pub db: DatabaseConnection,
}

impl AssessmentService {
    pub fn new(db: DatabaseConnection) -> Self {
        let db_clone = db.clone();
        Self {
            assessment_repo: AssessmentRepository::new(db.clone()),
            submission_repo: SubmissionRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            user_repo: UserRepository::new(db),
            db: db_clone,
        }
    }
}