use sea_orm::DatabaseConnection;
use std::sync::Arc;
use uuid::Uuid;

use crate::cache::{CacheKey, CacheInvalidator, RedisCache};
use crate::modules::assessment::repository::AssessmentRepository;
use crate::modules::class::repository::ClassRepository;
use crate::modules::grading::repository::GradeComputationRepository;
use crate::modules::auth::UserRepository;

pub struct AssessmentService {
    pub assessment_repo: AssessmentRepository,
    pub class_repo: ClassRepository,
    pub user_repo: UserRepository,
    pub grade_computation_repo: GradeComputationRepository,
    cache: Option<Arc<RedisCache>>,
    invalidator: Option<CacheInvalidator>,
}

impl AssessmentService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            assessment_repo: AssessmentRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            user_repo: UserRepository::new(db.clone()),
            grade_computation_repo: GradeComputationRepository::new(db),
            cache: None,
            invalidator: None,
        }
    }

    pub fn with_cache(mut self, cache: Arc<RedisCache>) -> Self {
        self.invalidator = Some(CacheInvalidator::new(cache.clone()));
        self.cache = Some(cache);
        self
    }

    pub async fn get_assessments_cached(
        &self,
        class_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> crate::utils::AppResult<crate::modules::assessment::schema::AssessmentListResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::AssessmentList(user_id, class_id).as_str();
            if let Some(cached) = cache.get::<crate::modules::assessment::schema::AssessmentListResponse>(&key).await {
                return Ok(cached);
            }
        }
        let result = self.get_assessments(class_id, user_id, role).await?;
        if let Some(ref cache) = self.cache {
            let key = CacheKey::AssessmentList(user_id, class_id).as_str();
            cache.set(&key, &result, cache.ttl.list_seconds).await;
        }
        Ok(result)
    }
}
