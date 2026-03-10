use std::sync::Arc;
use sea_orm::DatabaseConnection;

use crate::db::repositories::manifest_repository::ManifestRepository;
use crate::services::entitlement::EntitlementService;

/// Request for full sync
#[derive(Debug, Clone, serde::Deserialize)]
pub struct FullSyncRequest {
    pub device_id: String,
    pub class_ids: Option<Vec<String>>,  // empty/null = base data only; non-empty = batch request
}

/// Response for full sync
#[derive(Debug, Clone, serde::Serialize)]
pub struct FullSyncResponse {
    pub sync_token: String,
    pub server_time: String,
    pub user: Option<serde_json::Value>,
    pub classes: Vec<serde_json::Value>,
    pub enrollments: Vec<serde_json::Value>,
    pub enrolled_students: Vec<serde_json::Value>,
    pub assessments: Vec<serde_json::Value>,
    pub questions: Vec<serde_json::Value>,
    pub assessment_submissions: Vec<serde_json::Value>,
    pub assignments: Vec<serde_json::Value>,
    pub assignment_submissions: Vec<serde_json::Value>,
    pub learning_materials: Vec<serde_json::Value>,
    pub material_files: Vec<serde_json::Value>,
    pub submission_files: Vec<serde_json::Value>,
    pub assessment_statistics: Vec<serde_json::Value>,
    pub student_results: Vec<serde_json::Value>,
}

/// Service for full sync on login
pub struct SyncFullService {
    pub(super) entitlement_service: Arc<EntitlementService>,
    pub(super) manifest_repo: ManifestRepository,
    pub(super) db: DatabaseConnection,
}

impl SyncFullService {
    pub fn new(
        entitlement_service: Arc<EntitlementService>,
        manifest_repo: ManifestRepository,
        db: DatabaseConnection,
    ) -> Self {
        Self {
            entitlement_service,
            manifest_repo,
            db,
        }
    }
}
