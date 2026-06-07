use std::sync::Arc;
use uuid::Uuid;

use super::redis::RedisCache;
use super::keys::CacheKey;

#[derive(Clone)]
pub struct CacheInvalidator {
    cache: Arc<RedisCache>,
}

impl CacheInvalidator {
    pub fn new(cache: Arc<RedisCache>) -> Self {
        Self { cache }
    }

    pub async fn invalidate_class(&self, class_id: Uuid) {
        let keys = vec![
            CacheKey::ClassDetail(class_id).as_str(),
            CacheKey::ClassMetadata(class_id, "teacher".to_string()).as_str(),
            CacheKey::ClassMetadata(class_id, "student".to_string()).as_str(),
        ];
        self.cache.del_keys(keys).await;
    }

    pub async fn invalidate_student_classes(&self, student_id: Uuid) {
        self.cache.del(&CacheKey::ClassListStudent(student_id).as_str()).await;
        self.cache.del(&CacheKey::ClassMetadata(student_id, "student".to_string()).as_str()).await;
    }

    pub async fn invalidate_teacher_classes(&self, teacher_id: Uuid) {
        self.cache.del(&CacheKey::ClassListTeacher(teacher_id).as_str()).await;
        self.cache.del(&CacheKey::ClassMetadata(teacher_id, "teacher".to_string()).as_str()).await;
    }

    pub async fn invalidate_student_assignments(&self, student_id: Uuid) {
        self.cache.del(&CacheKey::AssignmentListStudent(student_id).as_str()).await;
    }

    pub async fn invalidate_teacher_assignments(&self, teacher_id: Uuid) {
        self.cache.del(&CacheKey::AssignmentListTeacher(teacher_id).as_str()).await;
    }

    pub async fn invalidate_assessments(&self, user_id: Uuid, class_id: Uuid) {
        self.cache.del(&CacheKey::AssessmentList(user_id, class_id).as_str()).await;
    }

    pub async fn invalidate_class_and_enrolled(&self, class_id: Uuid) {
        self.invalidate_class(class_id).await;
    }
}
