use sea_orm::DatabaseConnection;
use std::sync::Arc;
use crate::cache::{CacheInvalidator, RedisCache};
use crate::modules::admin::ActivityLogRepository;
use crate::modules::class::repository::ClassRepository;
use crate::modules::learning_material::repository::LearningMaterialRepository;

pub const MAX_FILE_SIZE_MB: i64 = 50;
pub const MAX_FILES_PER_MATERIAL: usize = 10;

pub struct LearningMaterialService {
    pub material_repo: LearningMaterialRepository,
    pub class_repo: ClassRepository,
    pub activity_log_repo: ActivityLogRepository,
    pub file_storage_path: String,
    pub file_encryption_key: [u8; 32],
    pub(crate) cache: Option<Arc<RedisCache>>,
    pub(crate) invalidator: Option<CacheInvalidator>,
}

impl LearningMaterialService {
    pub fn new(db: DatabaseConnection, file_storage_path: String, file_encryption_key: [u8; 32]) -> Self {
        Self {
            material_repo: LearningMaterialRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            activity_log_repo: ActivityLogRepository::new(db),
            file_storage_path,
            file_encryption_key,
            cache: None,
            invalidator: None,
        }
    }

    pub fn with_cache(mut self, cache: Arc<RedisCache>) -> Self {
        self.invalidator = Some(CacheInvalidator::new(cache.clone()));
        self.cache = Some(cache);
        self
    }
}