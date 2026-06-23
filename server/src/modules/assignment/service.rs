use sea_orm::DatabaseConnection;
use std::env;
use std::sync::Arc;

use crate::cache::{CacheKey, CacheInvalidator, RedisCache};
use crate::modules::assignment::repository::AssignmentRepository;
use crate::modules::admin::ActivityLogRepository;
use crate::modules::class::repository::ClassRepository;
use crate::modules::grading::repository::GradeComputationRepository;
use crate::modules::assignment::service_operations as ops;
use crate::utils::AppResult;

pub struct AssignmentService {
    pub assignment_repo: AssignmentRepository,
    pub class_repo: ClassRepository,
    pub activity_log_repo: ActivityLogRepository,
    pub file_storage_path: String,
    pub file_encryption_key: [u8; 32],
    pub grade_computation_repo: GradeComputationRepository,
    cache: Option<Arc<RedisCache>>,
    invalidator: Option<CacheInvalidator>,
}

impl AssignmentService {
    pub fn new(db: DatabaseConnection, file_encryption_key: [u8; 32]) -> Self {
        let file_storage_path = env::var("FILE_STORAGE_PATH")
            .unwrap_or_else(|_| "./uploads".to_string());

        Self {
            assignment_repo: AssignmentRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            activity_log_repo: ActivityLogRepository::new(db.clone()),
            grade_computation_repo: GradeComputationRepository::new(db.clone()),
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

    pub async fn create_assignment(
        &self,
        class_id: uuid::Uuid,
        request: crate::modules::assignment::schema::CreateAssignmentRequest,
        teacher_id: uuid::Uuid,
        client_id: Option<uuid::Uuid>,
    ) -> AppResult<crate::modules::assignment::schema::AssignmentResponse> {
        let result = ops::create_assignment(
            &self.assignment_repo,
            &self.class_repo,
            &self.activity_log_repo,
            class_id,
            request,
            teacher_id,
            client_id,
        ).await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_teacher_assignments(teacher_id).await;
        }
        Ok(result)
    }

    pub async fn get_assignments(
        &self,
        class_id: uuid::Uuid,
        user_id: uuid::Uuid,
        role: &str,
    ) -> AppResult<crate::modules::assignment::schema::AssignmentListResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::AssignmentListByClass(class_id, user_id, role.to_string()).as_str();
            if let Some(cached) = cache.get::<crate::modules::assignment::schema::AssignmentListResponse>(&key).await {
                return Ok(cached);
            }
        }
        let result = ops::get_assignments(
            &self.assignment_repo,
            &self.class_repo,
            class_id,
            user_id,
            role,
        ).await?;
        if let Some(ref cache) = self.cache {
            let key = CacheKey::AssignmentListByClass(class_id, user_id, role.to_string()).as_str();
            cache.set(&key, &result, cache.ttl.list_seconds).await;
        }
        Ok(result)
    }

    pub async fn get_assignment_detail(
        &self,
        assignment_id: uuid::Uuid,
        user_id: uuid::Uuid,
        role: &str,
    ) -> AppResult<crate::modules::assignment::schema::AssignmentResponse> {
        let cache_key = if role == "student" {
            CacheKey::AssignmentDetailStudent(assignment_id).as_str()
        } else {
            CacheKey::AssignmentDetailTeacher(assignment_id).as_str()
        };

        if let Some(ref cache) = self.cache {
            if let Some(cached) = cache.get::<crate::modules::assignment::schema::AssignmentResponse>(&cache_key).await {
                return Ok(cached);
            }
        }

        let result = ops::get_assignment_detail(
            &self.assignment_repo,
            &self.class_repo,
            assignment_id,
            user_id,
            role,
        ).await?;

        if let Some(ref cache) = self.cache {
            cache.set(&cache_key, &result, cache.ttl.detail_seconds).await;
        }

        Ok(result)
    }

    pub async fn get_student_assignments(
        &self,
        student_id: uuid::Uuid,
    ) -> AppResult<crate::modules::assignment::schema::AssignmentListResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::AssignmentListStudent(student_id).as_str();
            if let Some(cached) = cache.get::<crate::modules::assignment::schema::AssignmentListResponse>(&key).await {
                return Ok(cached);
            }
        }
        let result = ops::get_student_assignments(
            &self.assignment_repo,
            &self.class_repo,
            student_id,
        ).await?;
        if let Some(ref cache) = self.cache {
            let key = CacheKey::AssignmentListStudent(student_id).as_str();
            cache.set(&key, &result, cache.ttl.list_seconds).await;
        }
        Ok(result)
    }

    pub async fn update_assignment(
        &self,
        assignment_id: uuid::Uuid,
        request: crate::modules::assignment::schema::UpdateAssignmentRequest,
        teacher_id: uuid::Uuid,
    ) -> AppResult<crate::modules::assignment::schema::AssignmentResponse> {
        let result = ops::update_assignment(
            &self.assignment_repo,
            &self.class_repo,
            assignment_id,
            request,
            teacher_id,
        ).await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_assignment_detail(assignment_id).await;
            inv.invalidate_teacher_assignments(teacher_id).await;
        }
        Ok(result)
    }

    pub async fn publish_assignment(
        &self,
        assignment_id: uuid::Uuid,
        teacher_id: uuid::Uuid,
    ) -> AppResult<crate::modules::assignment::schema::AssignmentResponse> {
        let result = ops::publish_assignment(
            &self.assignment_repo,
            &self.class_repo,
            &self.activity_log_repo,
            &self.grade_computation_repo,
            assignment_id,
            teacher_id,
        ).await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_assignment_detail(assignment_id).await;
            inv.invalidate_teacher_assignments(teacher_id).await;
        }
        Ok(result)
    }

    pub async fn unpublish_assignment(
        &self,
        assignment_id: uuid::Uuid,
        teacher_id: uuid::Uuid,
    ) -> AppResult<crate::modules::assignment::schema::AssignmentResponse> {
        let result = ops::unpublish_assignment(
            &self.assignment_repo,
            &self.class_repo,
            &self.activity_log_repo,
            assignment_id,
            teacher_id,
        ).await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_assignment_detail(assignment_id).await;
            inv.invalidate_teacher_assignments(teacher_id).await;
        }
        Ok(result)
    }

    pub async fn soft_delete(
        &self,
        assignment_id: uuid::Uuid,
        teacher_id: uuid::Uuid,
    ) -> AppResult<()> {
        let result = ops::soft_delete(
            &self.assignment_repo,
            &self.class_repo,
            &self.activity_log_repo,
            assignment_id,
            teacher_id,
        ).await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_assignment_detail(assignment_id).await;
            inv.invalidate_teacher_assignments(teacher_id).await;
        }
        Ok(result)
    }

    pub async fn reorder_assignments(
        &self,
        class_id: uuid::Uuid,
        assignment_ids: Vec<uuid::Uuid>,
        teacher_id: uuid::Uuid,
    ) -> AppResult<()> {
        let result = ops::reorder_assignments(
            &self.assignment_repo,
            &self.class_repo,
            class_id,
            assignment_ids,
            teacher_id,
        ).await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_teacher_assignments(teacher_id).await;
        }
        Ok(result)
    }

    pub async fn get_assignments_metadata(
        &self,
        class_id: uuid::Uuid,
    ) -> AppResult<crate::modules::assignment::schema::AssignmentMetadataResponse> {
        ops::get_assignments_metadata(
            &self.assignment_repo,
            class_id,
        ).await
    }

    pub async fn create_or_get_submission(
        &self,
        assignment_id: uuid::Uuid,
        student_id: uuid::Uuid,
        client_submission_id: Option<uuid::Uuid>,
    ) -> AppResult<crate::modules::assignment::schema::AssignmentSubmissionResponse> {
        ops::create_or_get_submission(
            &self.assignment_repo,
            &self.class_repo,
            assignment_id,
            student_id,
            client_submission_id,
        ).await
    }

    pub async fn get_submission_detail(
        &self,
        submission_id: uuid::Uuid,
        user_id: uuid::Uuid,
        role: &str,
    ) -> AppResult<crate::modules::assignment::schema::AssignmentSubmissionResponse> {
        ops::get_submission_detail(
            &self.assignment_repo,
            &self.class_repo,
            submission_id,
            user_id,
            role,
        ).await
    }

    pub async fn submit_assignment(
        &self,
        submission_id: uuid::Uuid,
        student_id: uuid::Uuid,
        text_content: Option<String>,
    ) -> AppResult<crate::modules::assignment::schema::AssignmentSubmissionResponse> {
        ops::submit_assignment(
            &self.assignment_repo,
            &self.activity_log_repo,
            submission_id,
            student_id,
            text_content,
        ).await
    }

    pub async fn upload_file(
        &self,
        submission_id: uuid::Uuid,
        student_id: uuid::Uuid,
        file_name: String,
        file_type: String,
        file_data: Vec<u8>,
    ) -> AppResult<crate::modules::assignment::schema::FileMetadataResponse> {
        ops::upload_file(
            &self.assignment_repo,
            &self.file_storage_path,
            &self.file_encryption_key,
            submission_id,
            student_id,
            file_name,
            file_type,
            file_data,
        ).await
    }

    pub async fn download_file(
        &self,
        file_id: uuid::Uuid,
        user_id: uuid::Uuid,
    ) -> AppResult<(String, String, Vec<u8>)> {
        ops::download_file(
            &self.assignment_repo,
            &self.file_encryption_key,
            file_id,
            user_id,
        ).await
    }

    pub async fn delete_file(
        &self,
        file_id: uuid::Uuid,
        student_id: uuid::Uuid,
    ) -> AppResult<()> {
        ops::delete_file(
            &self.assignment_repo,
            file_id,
            student_id,
        ).await
    }

    pub async fn get_submissions(
        &self,
        assignment_id: uuid::Uuid,
        teacher_id: uuid::Uuid,
    ) -> AppResult<crate::modules::assignment::schema::SubmissionListResponse> {
        ops::get_submissions(
            &self.assignment_repo,
            &self.class_repo,
            assignment_id,
            teacher_id,
        ).await
    }

    pub async fn get_student_assignment_submission(
        &self,
        assignment_id: uuid::Uuid,
        student_id: uuid::Uuid,
        user_id: uuid::Uuid,
        role: &str,
    ) -> AppResult<Option<crate::modules::assignment::schema::AssignmentSubmissionResponse>> {
        ops::get_student_assignment_submission(
            &self.assignment_repo,
            &self.class_repo,
            assignment_id,
            student_id,
            user_id,
            role,
        ).await
    }

    pub async fn get_student_assignment_submissions(
        &self,
        assignment_id: uuid::Uuid,
        student_id: uuid::Uuid,
        teacher_id: uuid::Uuid,
    ) -> AppResult<crate::modules::assignment::schema::AssignmentSubmissionResponse> {
        ops::get_student_assignment_submissions(
            &self.assignment_repo,
            &self.class_repo,
            assignment_id,
            student_id,
            teacher_id,
        ).await
    }

    pub async fn grade_submission(
        &self,
        submission_id: uuid::Uuid,
        request: crate::modules::assignment::schema::GradeSubmissionRequest,
        teacher_id: uuid::Uuid,
    ) -> AppResult<crate::modules::assignment::schema::AssignmentSubmissionResponse> {
        ops::grade_submission(
            &self.assignment_repo,
            &self.class_repo,
            &self.activity_log_repo,
            &self.grade_computation_repo,
            self.invalidator.as_ref(),
            submission_id,
            request,
            teacher_id,
        ).await
    }

    pub async fn return_submission(
        &self,
        submission_id: uuid::Uuid,
        teacher_id: uuid::Uuid,
    ) -> AppResult<crate::modules::assignment::schema::AssignmentSubmissionResponse> {
        ops::return_submission(
            &self.assignment_repo,
            &self.class_repo,
            &self.activity_log_repo,
            submission_id,
            teacher_id,
        ).await
    }
}
