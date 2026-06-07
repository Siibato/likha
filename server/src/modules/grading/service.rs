use sea_orm::DatabaseConnection;
use std::sync::Arc;

use crate::cache::{CacheInvalidator, RedisCache};
use crate::modules::class::repository::ClassRepository;
use crate::modules::grading::repository::GradeComputationRepository;

pub struct GradeComputationService {
    pub repo: GradeComputationRepository,
    pub class_repo: ClassRepository,
    pub db: DatabaseConnection,
    pub(crate) cache: Option<Arc<RedisCache>>,
    pub(crate) invalidator: Option<CacheInvalidator>,
}

impl GradeComputationService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            repo: GradeComputationRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            db,
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
