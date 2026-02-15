use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

/// Represents a single sync operation from the mobile client
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncQueueEntry {
    pub id: String,
    pub entity_type: String,
    pub operation: String,
    pub payload: Value,
    pub created_at: DateTime<Utc>,
}

/// Request body for syncing offline changes
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncRequest {
    /// List of operations to sync (ordered by creation time)
    pub operations: Vec<SyncQueueEntry>,
    /// Timestamp of last successful sync on client
    pub last_sync_at: Option<DateTime<Utc>>,
    /// Client version/identifier
    pub client_version: Option<String>,
}

/// Individual sync operation result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncOperationResult {
    pub id: String,
    pub entity_type: String,
    pub operation: String,
    /// true if successful, false if failed
    pub success: bool,
    /// If successful and this was a create, the server-assigned ID
    pub server_id: Option<String>,
    /// If failed, the error message
    pub error: Option<String>,
    /// New version/timestamp of affected entity (for conflict detection)
    pub updated_at: Option<DateTime<Utc>>,
}

/// Response from sync endpoint
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncResponse {
    /// Results of each operation in order
    pub results: Vec<SyncOperationResult>,
    /// List of entities to cache (server sends current state of all affected data)
    pub cache_updates: CacheUpdates,
    /// Server timestamp for next sync
    pub server_time: DateTime<Utc>,
    /// Conflicts detected (for user resolution)
    pub conflicts: Vec<SyncConflict>,
}

/// Cache updates grouped by entity type
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct CacheUpdates {
    pub users: Vec<Value>,
    pub classes: Vec<Value>,
    pub class_enrollments: Vec<Value>,
    pub assessments: Vec<Value>,
    pub questions: Vec<Value>,
    pub assessment_submissions: Vec<Value>,
    pub assignments: Vec<Value>,
    pub assignment_submissions: Vec<Value>,
    pub submission_files: Vec<Value>,
    pub learning_materials: Vec<Value>,
    pub material_files: Vec<Value>,
}

/// Represents a conflict between client and server
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncConflict {
    pub entity_type: String,
    pub entity_id: String,
    pub operation: String,
    pub client_version: DateTime<Utc>,
    pub server_version: DateTime<Utc>,
    pub client_data: Value,
    pub server_data: Value,
    /// Instructions for resolution (server_wins, client_wins, manual)
    pub resolution_strategy: String,
}

/// Request for bulk cache refresh (when client wants full sync)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FullSyncRequest {
    pub last_sync_at: Option<DateTime<Utc>>,
}

/// Response with all cached data for specific classes
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FullSyncResponse {
    pub cache_updates: CacheUpdates,
    pub server_time: DateTime<Utc>,
}

/// Health check for sync system
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncHealthResponse {
    pub status: String,
    pub server_time: DateTime<Utc>,
    pub database_reachable: bool,
    pub last_sync_completed_at: Option<DateTime<Utc>>,
}

/// Conflict resolution request from client
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConflictResolutionRequest {
    pub entity_type: String,
    pub entity_id: String,
    pub operation: String,
    /// "server_wins", "client_wins", or custom resolution data
    pub resolution: String,
}

/// Result of conflict resolution
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConflictResolutionResponse {
    pub success: bool,
    pub message: Option<String>,
    pub updated_entity: Option<Value>,
}

/// ID mapping response (for reconciliation of temp IDs to server IDs)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IdMappingResponse {
    /// Maps from temporary client ID to permanent server ID
    pub mappings: Vec<IdMapping>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IdMapping {
    pub temp_id: String,
    pub server_id: String,
    pub entity_type: String,
}

/// Change tracker for delta sync
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EntityChanges {
    pub entity_id: String,
    pub entity_type: String,
    pub changed_fields: Vec<String>,
    pub updated_at: DateTime<Utc>,
}

/// Sync statistics for monitoring
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncStatistics {
    pub total_operations: usize,
    pub successful_operations: usize,
    pub failed_operations: usize,
    pub conflicts_detected: usize,
    pub sync_duration_ms: u64,
    pub timestamp: DateTime<Utc>,
}

/// Query parameters for GET /api/v1/changes
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChangesQueryParams {
    pub since_sequence: i64,
    pub limit: Option<u64>,
}

/// Individual change log entry in response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChangeLogEntry {
    pub sequence: i64,
    pub entity_type: String,
    pub entity_id: String,
    pub operation: String,
    pub performed_by: String,
    pub payload: Option<Value>,
    pub created_at: String,
}

/// Response from GET /api/v1/changes endpoint
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChangesResponse {
    pub changes: Vec<ChangeLogEntry>,
    pub latest_sequence: i64,
    pub has_more: bool,
    pub server_time: String,
}

/// Response with database ID for cache validation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DatabaseIdResponse {
    pub database_id: String,
    pub created_at: String,
}
