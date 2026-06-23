use super::delegate::PushDelegate;
use crate::modules::entitlement::EntitlementService;
use std::sync::Arc;

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
    pub processed_ops_repo: Arc<crate::modules::sync::ProcessedOperationsRepository>,
    pub delegates: Vec<Arc<dyn PushDelegate>>,
}

impl SyncPushService {
    pub fn new(
        entitlement_service: Arc<EntitlementService>,
        processed_ops_repo: Arc<crate::modules::sync::ProcessedOperationsRepository>,
        delegates: Vec<Arc<dyn PushDelegate>>,
    ) -> Self {
        Self {
            entitlement_service,
            processed_ops_repo,
            delegates,
        }
    }
}
