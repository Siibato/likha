use std::sync::Arc;
use sea_orm::DatabaseConnection;
use serde_json::Value;

use crate::db::repositories::manifest_repository::ManifestRepository;
use crate::services::entitlement::EntitlementService;

/// Request for delta sync
#[derive(Debug, Clone, serde::Deserialize)]
pub struct DeltaRequest {
    pub device_id: String,
    pub last_sync_at: String, // ISO8601
}

/// Entity deltas (updated and deleted records)
#[derive(Debug, Clone, serde::Serialize)]
pub struct EntityDeltas {
    pub updated: Vec<Value>,
    pub deleted: Vec<String>,
}

/// Payload of deltas
#[derive(Debug, Clone, serde::Serialize)]
pub struct DeltaPayload {
    pub classes: EntityDeltas,
    pub enrollments: EntityDeltas,
    pub assessments: EntityDeltas,
    pub questions: EntityDeltas,
    pub assessment_submissions: EntityDeltas,
    pub assignments: EntityDeltas,
    pub assignment_submissions: EntityDeltas,
    pub learning_materials: EntityDeltas,
    pub grade_configs: EntityDeltas,
    pub grade_items: EntityDeltas,
    pub grade_scores: EntityDeltas,
    pub period_grades: EntityDeltas,
    pub table_of_specifications: EntityDeltas,
    pub tos_competencies: EntityDeltas,
}

/// Response variants
#[derive(Debug, Clone, serde::Serialize)]
#[serde(untagged)]
pub enum DeltaResponse {
    DataExpired {
        status: String,
        message: String,
    },
    Deltas {
        sync_token: String,
        server_time: String,
        deltas: DeltaPayload,
    },
}

/// Service for delta sync
pub struct SyncDeltaService {
    pub(super) entitlement_service: Arc<EntitlementService>,
    pub(super) manifest_repo: ManifestRepository,
    pub(super) db: DatabaseConnection,
}

impl SyncDeltaService {
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
