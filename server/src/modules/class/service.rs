use sea_orm::DatabaseConnection;
use std::sync::Arc;
use uuid::Uuid;

use crate::cache::{CacheInvalidator, CacheKey, RedisCache};
use crate::modules::auth::UserRepository;
use crate::modules::class::repository::ClassRepository;
use crate::modules::class::schema::{
    ClassDetailResponse, ClassListResponse, ClassMetadataResponse, ClassResponse,
    CreateClassRequest, EnrollmentResponse, UpdateClassRequest,
};
use crate::modules::class::service_operations as ops;
use crate::utils::AppResult;

pub struct ClassService {
    pub class_repo: ClassRepository,
    pub user_repo: UserRepository,
    cache: Option<Arc<RedisCache>>,
    invalidator: Option<CacheInvalidator>,
}

impl ClassService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            class_repo: ClassRepository::new(db.clone()),
            user_repo: UserRepository::new(db),
            cache: None,
            invalidator: None,
        }
    }

    pub fn with_cache(mut self, cache: Arc<RedisCache>) -> Self {
        self.invalidator = Some(CacheInvalidator::new(cache.clone()));
        self.cache = Some(cache);
        self
    }

    pub async fn create_class(
        &self,
        request: CreateClassRequest,
        teacher_id: Uuid,
        client_id: Option<Uuid>,
    ) -> AppResult<ClassResponse> {
        let result = ops::create_class(
            &self.class_repo,
            &self.user_repo,
            request,
            teacher_id,
            client_id,
        )
        .await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_teacher_classes(teacher_id).await;
        }
        Ok(result)
    }

    pub async fn update_class(
        &self,
        class_id: Uuid,
        request: UpdateClassRequest,
        teacher_id: Uuid,
        caller_role: &str,
    ) -> AppResult<ClassResponse> {
        let result = ops::update_class(
            &self.class_repo,
            &self.user_repo,
            class_id,
            request,
            teacher_id,
            caller_role,
        )
        .await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_class_and_enrolled(class_id).await;
            inv.invalidate_teacher_classes(teacher_id).await;
        }
        Ok(result)
    }

    pub async fn get_teacher_classes(&self, teacher_id: Uuid) -> AppResult<ClassListResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::ClassListTeacher(teacher_id).as_str();
            if let Some(cached) = cache.get::<ClassListResponse>(&key).await {
                return Ok(cached);
            }
        }
        let result =
            ops::get_teacher_classes(&self.class_repo, &self.user_repo, teacher_id).await?;
        if let Some(ref cache) = self.cache {
            let key = CacheKey::ClassListTeacher(teacher_id).as_str();
            cache.set(&key, &result, cache.ttl.list_seconds).await;
        }
        Ok(result)
    }

    pub async fn get_student_classes(&self, student_id: Uuid) -> AppResult<ClassListResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::ClassListStudent(student_id).as_str();
            if let Some(cached) = cache.get::<ClassListResponse>(&key).await {
                return Ok(cached);
            }
        }
        let result = ops::get_student_classes(&self.class_repo, student_id).await?;
        if let Some(ref cache) = self.cache {
            let key = CacheKey::ClassListStudent(student_id).as_str();
            cache.set(&key, &result, cache.ttl.list_seconds).await;
        }
        Ok(result)
    }

    pub async fn get_all_classes(&self) -> AppResult<ClassListResponse> {
        ops::get_all_classes(&self.class_repo).await
    }

    pub async fn soft_delete(&self, class_id: Uuid, user_id: Uuid, role: &str) -> AppResult<()> {
        let result = ops::soft_delete(&self.class_repo, class_id, user_id, role).await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_class_and_enrolled(class_id).await;
            inv.invalidate_teacher_classes(user_id).await;
        }
        Ok(result)
    }

    pub async fn get_class_detail(&self, class_id: Uuid) -> AppResult<ClassDetailResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::ClassDetail(class_id).as_str();
            if let Some(cached) = cache.get::<ClassDetailResponse>(&key).await {
                return Ok(cached);
            }
        }
        let result = ops::get_class_detail(&self.class_repo, &self.user_repo, class_id).await?;
        if let Some(ref cache) = self.cache {
            let key = CacheKey::ClassDetail(class_id).as_str();
            cache.set(&key, &result, cache.ttl.detail_seconds).await;
        }
        Ok(result)
    }

    pub async fn add_student(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
        role: &str,
    ) -> AppResult<EnrollmentResponse> {
        let result = ops::add_student(
            &self.class_repo,
            &self.user_repo,
            class_id,
            student_id,
            teacher_id,
            role,
        )
        .await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_student_classes(student_id).await;
            inv.invalidate_class_and_enrolled(class_id).await;
        }
        Ok(result)
    }

    pub async fn remove_student(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
        role: &str,
    ) -> AppResult<()> {
        let result =
            ops::remove_student(&self.class_repo, class_id, student_id, teacher_id, role).await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_student_classes(student_id).await;
            inv.invalidate_class_and_enrolled(class_id).await;
        }
        Ok(result)
    }

    pub async fn is_student_enrolled(&self, class_id: Uuid, student_id: Uuid) -> AppResult<bool> {
        ops::is_student_enrolled(&self.class_repo, class_id, student_id).await
    }

    pub async fn get_participants(&self, class_id: Uuid) -> AppResult<Vec<EnrollmentResponse>> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::ClassParticipants(class_id).as_str();
            if let Some(cached) = cache.get::<Vec<EnrollmentResponse>>(&key).await {
                return Ok(cached);
            }
        }
        let result = ops::get_participants(&self.class_repo, class_id).await?;
        if let Some(ref cache) = self.cache {
            let key = CacheKey::ClassParticipants(class_id).as_str();
            cache.set(&key, &result, cache.ttl.list_seconds).await;
        }
        Ok(result)
    }

    pub async fn get_classes_metadata(
        &self,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<ClassMetadataResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::ClassMetadata(user_id, role.to_string()).as_str();
            if let Some(cached) = cache.get::<ClassMetadataResponse>(&key).await {
                return Ok(cached);
            }
        }
        let result = ops::get_classes_metadata(&self.class_repo, user_id, role).await?;
        if let Some(ref cache) = self.cache {
            let key = CacheKey::ClassMetadata(user_id, role.to_string()).as_str();
            cache.set(&key, &result, cache.ttl.list_seconds).await;
        }
        Ok(result)
    }
}
