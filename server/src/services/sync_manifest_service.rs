use chrono::Utc;
use serde_json::json;
use uuid::Uuid;

use crate::services::entitlement_service::{EntitlementService, UserManifest};
use crate::utils::{AppError, AppResult};

/// Response for manifest endpoint
#[derive(Debug, Clone, serde::Serialize)]
pub struct ManifestResponse {
    pub classes: serde_json::Value,
    pub enrollments: serde_json::Value,
    pub assessments: serde_json::Value,
    pub assessment_questions: serde_json::Value,
    pub assessment_submissions: serde_json::Value,
    pub assignments: serde_json::Value,
    pub assignment_submissions: serde_json::Value,
    pub learning_materials: serde_json::Value,
    pub activity_logs: serde_json::Value,
    pub server_time: String,
}

/// Service for generating sync manifests
pub struct SyncManifestService {
    entitlement_service: std::sync::Arc<EntitlementService>,
}

impl SyncManifestService {
    pub fn new(entitlement_service: std::sync::Arc<EntitlementService>) -> Self {
        Self { entitlement_service }
    }

    /// Get manifest of all records user is entitled to
    pub async fn get_manifest(
        &self,
        user_id: Uuid,
        user_role: &str,
    ) -> AppResult<ManifestResponse> {
        // Get all records user is entitled to
        let manifest: UserManifest = self
            .entitlement_service
            .get_user_manifest(user_id, user_role)
            .await?;

        // Convert to API response format
        Ok(ManifestResponse {
            classes: json!(manifest.classes.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>()),
            enrollments: json!(manifest.enrollments.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>()),
            assessments: json!(manifest.assessments.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>()),
            assessment_questions: json!(manifest.assessment_questions.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>()),
            assessment_submissions: json!(manifest.assessment_submissions.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>()),
            assignments: json!(manifest.assignments.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>()),
            assignment_submissions: json!(manifest.assignment_submissions.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>()),
            learning_materials: json!(manifest.learning_materials.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>()),
            activity_logs: json!(manifest.activity_logs.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>()),
            server_time: Utc::now().to_rfc3339(),
        })
    }
}
