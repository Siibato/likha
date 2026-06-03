use sea_orm::DatabaseConnection;
use uuid::Uuid;

use crate::modules::admin::ActivityLogRepository;
use crate::modules::setup::repository::SetupRepository;
use crate::modules::setup::schema::{
    QrCodeResponse, SchoolSettingsResponse, ShortCodeResponse, UpdateCodeRequest,
    UpdateSchoolSettingsRequest, VerifyResponse,
};
use crate::modules::setup::service_operations as ops;
use crate::utils::AppResult;

pub struct SetupService {
    db: DatabaseConnection,
    setup_repo: SetupRepository,
    activity_log_repo: ActivityLogRepository,
}

impl SetupService {
    /// Creates the service and seeds the school_settings row if it doesn't exist.
    pub async fn new(db: DatabaseConnection, default_school_code: String) -> Self {
        let setup_repo = SetupRepository::new(db.clone());
        let activity_log_repo = ActivityLogRepository::new(db.clone());
        
        if let Err(e) = ops::seed_settings(&db, &default_school_code).await {
            tracing::error!("Failed to seed school_settings: {}", e);
        }

        Self {
            db,
            setup_repo,
            activity_log_repo,
        }
    }

    // ---------------------------------------------------------------------------
    // Public endpoints
    // ---------------------------------------------------------------------------

    /// Verifies a school code (case-insensitive). Returns school_name on match.
    pub async fn verify_code(&self, code: &str) -> AppResult<VerifyResponse> {
        ops::verify_code(&self.setup_repo, code).await
    }

    /// Returns public school info (school_name only).
    pub async fn get_school_info(&self) -> AppResult<VerifyResponse> {
        ops::get_school_info(&self.setup_repo).await
    }

    // ---------------------------------------------------------------------------
    // Admin endpoints
    // ---------------------------------------------------------------------------

    /// Returns all school settings.
    pub async fn get_school_settings(&self) -> AppResult<SchoolSettingsResponse> {
        ops::get_school_settings(&self.setup_repo).await
    }

    /// Updates school details (name, region, division, year).
    pub async fn update_school_settings(
        &self,
        request: UpdateSchoolSettingsRequest,
    ) -> AppResult<SchoolSettingsResponse> {
        ops::update_school_settings(&self.setup_repo, request).await
    }

    /// Updates the school code in the database.
    pub async fn update_code(&self, request: UpdateCodeRequest, admin_id: Uuid) -> AppResult<()> {
        ops::update_school_code(&self.setup_repo, &self.activity_log_repo, request.code, admin_id).await
    }

    /// Returns the current school code.
    pub async fn get_school_code(&self) -> AppResult<ShortCodeResponse> {
        ops::get_school_code(&self.setup_repo).await
    }

    /// Generates a QR code PNG containing the plain school code text.
    pub async fn generate_qr_code(&self) -> AppResult<QrCodeResponse> {
        ops::generate_qr_code(&self.setup_repo).await
    }
}
