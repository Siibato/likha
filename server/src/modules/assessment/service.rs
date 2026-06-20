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
    pub(crate) cache: Option<Arc<RedisCache>>,
    pub(crate) invalidator: Option<CacheInvalidator>,
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

    pub async fn get_assessment_detail_cached(
        &self,
        assessment_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> crate::utils::AppResult<crate::modules::assessment::schema::AssessmentDetailResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::AssessmentDetail(assessment_id, role.to_string()).as_str();
            if let Some(cached) = cache.get::<crate::modules::assessment::schema::AssessmentDetailResponse>(&key).await {
                return Ok(cached);
            }
        }
        let result = self.get_assessment_detail(assessment_id, user_id, role).await?;
        if let Some(ref cache) = self.cache {
            let key = CacheKey::AssessmentDetail(assessment_id, role.to_string()).as_str();
            cache.set(&key, &result, cache.ttl.detail_seconds).await;
        }
        Ok(result)
    }

    pub async fn get_submissions_cached(
        &self,
        assessment_id: Uuid,
        user_id: Uuid,
    ) -> crate::utils::AppResult<crate::modules::assessment::schema::SubmissionListResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::AssessmentSubmissions(assessment_id).as_str();
            if let Some(cached) = cache.get::<crate::modules::assessment::schema::SubmissionListResponse>(&key).await {
                return Ok(cached);
            }
        }
        let result = self.get_submissions(assessment_id, user_id).await?;
        if let Some(ref cache) = self.cache {
            let key = CacheKey::AssessmentSubmissions(assessment_id).as_str();
            cache.set(&key, &result, cache.ttl.list_seconds).await;
        }
        Ok(result)
    }

    pub async fn get_submission_detail_cached(
        &self,
        submission_id: Uuid,
        user_id: Uuid,
    ) -> crate::utils::AppResult<crate::modules::assessment::schema::SubmissionDetailResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::AssessmentSubmissionDetail(submission_id).as_str();
            if let Some(cached) = cache.get::<crate::modules::assessment::schema::SubmissionDetailResponse>(&key).await {
                return Ok(cached);
            }
        }
        let result = self.get_submission_detail(submission_id, user_id).await?;
        if let Some(ref cache) = self.cache {
            let key = CacheKey::AssessmentSubmissionDetail(submission_id).as_str();
            cache.set(&key, &result, cache.ttl.detail_seconds).await;
        }
        Ok(result)
    }

    pub async fn get_student_results_cached(
        &self,
        submission_id: Uuid,
        user_id: Uuid,
    ) -> crate::utils::AppResult<crate::modules::assessment::schema::StudentResultResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::StudentResults(submission_id).as_str();
            if let Some(cached) = cache.get::<crate::modules::assessment::schema::StudentResultResponse>(&key).await {
                return Ok(cached);
            }
        }
        let result = self.get_student_results(submission_id, user_id).await?;
        if let Some(ref cache) = self.cache {
            let key = CacheKey::StudentResults(submission_id).as_str();
            cache.set(&key, &result, cache.ttl.detail_seconds).await;
        }
        Ok(result)
    }

    pub async fn get_student_submission_cached(
        &self,
        assessment_id: Uuid,
        student_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> crate::utils::AppResult<Option<crate::modules::assessment::schema::SubmissionSummaryResponse>> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::AssessmentStudentSubmission(assessment_id, student_id).as_str();
            if let Some(cached) = cache.get::<crate::modules::assessment::schema::SubmissionSummaryResponse>(&key).await {
                return Ok(Some(cached));
            }
        }
        let result = self.get_student_submission(assessment_id, student_id, user_id, role).await?;
        if let (Some(ref cache), Some(ref data)) = (self.cache.clone(), &result) {
            let key = CacheKey::AssessmentStudentSubmission(assessment_id, student_id).as_str();
            cache.set(&key, data, cache.ttl.detail_seconds).await;
        }
        Ok(result)
    }

    pub async fn get_student_assessment_submissions_cached(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        user_id: Uuid,
    ) -> crate::utils::AppResult<crate::modules::assessment::schema::StudentAssessmentSubmissionsResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::StudentAssessmentSubmissions(class_id, student_id).as_str();
            if let Some(cached) = cache.get::<crate::modules::assessment::schema::StudentAssessmentSubmissionsResponse>(&key).await {
                return Ok(cached);
            }
        }
        let result = self.get_student_assessment_submissions(class_id, student_id, user_id).await?;
        if let Some(ref cache) = self.cache {
            let key = CacheKey::StudentAssessmentSubmissions(class_id, student_id).as_str();
            cache.set(&key, &result, cache.ttl.list_seconds).await;
        }
        Ok(result)
    }
}
