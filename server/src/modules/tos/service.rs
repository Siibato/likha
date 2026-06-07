use sea_orm::DatabaseConnection;
use std::sync::Arc;

use crate::cache::{CacheInvalidator, RedisCache};
use crate::modules::class::repository::ClassRepository;
use crate::modules::tos::repository::TosRepository;

pub struct TosService {
    pub tos_repo: TosRepository,
    pub class_repo: ClassRepository,
    pub(crate) cache: Option<Arc<RedisCache>>,
    pub(crate) invalidator: Option<CacheInvalidator>,
}

impl TosService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            tos_repo: TosRepository::new(db.clone()),
            class_repo: ClassRepository::new(db),
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
