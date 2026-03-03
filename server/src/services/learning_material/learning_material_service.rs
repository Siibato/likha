use sea_orm::DatabaseConnection;
use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::db::repositories::change_log_repository::ChangeLogRepository;
use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::learning_material_repository::LearningMaterialRepository;

pub const MAX_FILE_SIZE_MB: i64 = 50;
pub const MAX_FILES_PER_MATERIAL: usize = 10;

pub struct LearningMaterialService {
    pub material_repo: LearningMaterialRepository,
    pub class_repo: ClassRepository,
    pub activity_log_repo: ActivityLogRepository,
    pub change_log_repo: ChangeLogRepository,
}

impl LearningMaterialService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            material_repo: LearningMaterialRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            activity_log_repo: ActivityLogRepository::new(db.clone()),
            change_log_repo: ChangeLogRepository::new(db),
        }
    }
}