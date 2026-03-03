use std::sync::Arc;
use crate::services::entitlement::EntitlementService;
use crate::services::class::ClassService;
use crate::services::assessment::AssessmentService;
use crate::services::assignment::AssignmentService;
use crate::services::learning_material::LearningMaterialService;
use crate::services::auth::AuthService;

#[derive(Debug, Clone, serde::Deserialize)]
pub struct SyncQueueEntry {
    pub id: String,
    pub entity_type: String,
    pub operation: String,
    pub payload: serde_json::Value,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct OperationResult {
    pub id: String,
    pub entity_type: String,
    pub operation: String,
    pub success: bool,
    pub server_id: Option<String>,
    pub error: Option<String>,
    pub updated_at: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub metadata: Option<serde_json::Value>,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct PushResponse {
    pub results: Vec<OperationResult>,
}

pub struct SyncPushService {
    pub entitlement_service: Arc<EntitlementService>,
    pub class_service: Arc<ClassService>,
    pub assessment_service: Arc<AssessmentService>,
    pub assignment_service: Arc<AssignmentService>,
    pub material_service: Arc<LearningMaterialService>,
    pub auth_service: Arc<AuthService>,
    pub processed_ops_repo: Arc<crate::db::repositories::processed_operations_repository::ProcessedOperationsRepository>,
}

impl SyncPushService {
    pub fn new(
        entitlement_service: Arc<EntitlementService>,
        class_service: Arc<ClassService>,
        assessment_service: Arc<AssessmentService>,
        assignment_service: Arc<AssignmentService>,
        material_service: Arc<LearningMaterialService>,
        auth_service: Arc<AuthService>,
        processed_ops_repo: Arc<crate::db::repositories::processed_operations_repository::ProcessedOperationsRepository>,
    ) -> Self {
        Self {
            entitlement_service,
            class_service,
            assessment_service,
            assignment_service,
            material_service,
            auth_service,
            processed_ops_repo,
        }
    }
}