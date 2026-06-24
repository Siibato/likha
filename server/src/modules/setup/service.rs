use sea_orm::DatabaseConnection;
use std::sync::Arc;
use uuid::Uuid;

use crate::cache::{CacheInvalidator, CacheKey, RedisCache};
use crate::modules::admin::ActivityLogRepository;
use crate::modules::setup::repository::SetupRepository;
use crate::modules::setup::schema::{
    QrCodeResponse, SchoolDetailsResponse, ShortCodeResponse, UpdateCodeRequest,
    UpdateSchoolDetailsRequest, VerifyResponse,
};
use crate::modules::setup::service_operations as ops;
use crate::utils::AppResult;

pub struct SetupService {
    setup_repo: SetupRepository,
    activity_log_repo: ActivityLogRepository,
    cache: Option<Arc<RedisCache>>,
    invalidator: Option<CacheInvalidator>,
}

impl SetupService {
    pub async fn new(db: DatabaseConnection, default_school_code: String) -> Self {
        let setup_repo = SetupRepository::new(db.clone());
        let activity_log_repo = ActivityLogRepository::new(db.clone());

        if let Err(e) = ops::seed_settings(&db, &default_school_code).await {
            tracing::error!("Failed to seed school_details: {}", e);
        }

        Self {
            setup_repo,
            activity_log_repo,
            cache: None,
            invalidator: None,
        }
    }

    pub fn with_cache(mut self, cache: Arc<RedisCache>) -> Self {
        self.invalidator = Some(CacheInvalidator::new(cache.clone()));
        self.cache = Some(cache);
        self
    }

    // ---------------------------------------------------------------------------
    // Public endpoints
    // ---------------------------------------------------------------------------

    /// Verifies a school code (case-insensitive). Returns school_name on match.
    pub async fn verify_school_code(&self, code: &str) -> AppResult<VerifyResponse> {
        ops::verify_code(&self.setup_repo, code).await
    }

    /// Returns public school info (school_name only).
    pub async fn get_school_info(&self) -> AppResult<VerifyResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::SchoolInfo.as_str();
            if let Some(cached) = cache.get::<VerifyResponse>(&key).await {
                return Ok(cached);
            }
        }
        let result = ops::get_school_info(&self.setup_repo).await?;
        if let Some(ref cache) = self.cache {
            let key = CacheKey::SchoolInfo.as_str();
            cache.set(&key, &result, cache.ttl.static_seconds).await;
        }
        Ok(result)
    }

    // ---------------------------------------------------------------------------
    // Admin endpoints
    // ---------------------------------------------------------------------------

    /// Returns all school details.
    pub async fn get_school_details(&self) -> AppResult<SchoolDetailsResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::SchoolDetails.as_str();
            if let Some(cached) = cache.get::<SchoolDetailsResponse>(&key).await {
                return Ok(cached);
            }
        }
        let result = ops::get_school_details(&self.setup_repo).await?;
        if let Some(ref cache) = self.cache {
            let key = CacheKey::SchoolDetails.as_str();
            cache.set(&key, &result, cache.ttl.static_seconds).await;
        }
        Ok(result)
    }

    /// Updates school details (name, region, division, year).
    pub async fn update_school_details(
        &self,
        request: UpdateSchoolDetailsRequest,
    ) -> AppResult<SchoolDetailsResponse> {
        let result = ops::update_school_details(&self.setup_repo, request).await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_school_details().await;
            inv.invalidate_school_info().await;
        }
        Ok(result)
    }

    /// Updates the school code in the database.
    pub async fn update_code(&self, request: UpdateCodeRequest, admin_id: Uuid) -> AppResult<()> {
        let result = ops::update_school_code(
            &self.setup_repo,
            &self.activity_log_repo,
            request.code,
            admin_id,
        )
        .await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_school_code().await;
            inv.invalidate_school_details().await;
        }
        Ok(result)
    }

    /// Returns the current school code.
    pub async fn get_school_code(&self) -> AppResult<ShortCodeResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::SchoolCode.as_str();
            if let Some(cached) = cache.get::<ShortCodeResponse>(&key).await {
                return Ok(cached);
            }
        }
        let result = ops::get_school_code(&self.setup_repo).await?;
        if let Some(ref cache) = self.cache {
            let key = CacheKey::SchoolCode.as_str();
            cache.set(&key, &result, cache.ttl.static_seconds).await;
        }
        Ok(result)
    }

    /// Generates a QR code PNG containing the plain school code text.
    pub async fn generate_qr_code(&self) -> AppResult<QrCodeResponse> {
        ops::generate_qr_code(&self.setup_repo).await
    }
}
