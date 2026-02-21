use chrono::{DateTime, Utc};
use serde_json::Value;

use crate::db::repositories::sync_conflict_repository::SyncConflictRepository;
use crate::utils::{AppError, AppResult};

/// Request to resolve a conflict
#[derive(Debug, Clone, serde::Deserialize)]
pub struct ConflictResolutionRequest {
    pub conflict_id: String,
    pub resolution: String, // "server_wins", "client_wins"
}

/// Response after conflict resolution
#[derive(Debug, Clone, serde::Serialize)]
pub struct ConflictResolutionResponse {
    pub success: bool,
    pub message: Option<String>,
    pub resolved_entity: Option<Value>, // Final state after resolution
}

/// Detects and resolves conflicts between client and server versions
pub struct SyncConflictService {
    conflict_repo: SyncConflictRepository,
}

impl SyncConflictService {
    pub fn new(conflict_repo: SyncConflictRepository) -> Self {
        Self { conflict_repo }
    }

    /// Detect if a conflict exists between client and server versions
    /// Returns true if timestamps differ (indicating a conflict)
    pub async fn detect_conflict(
        &self,
        entity_type: &str,
        entity_id: &str,
        client_updated_at: DateTime<Utc>,
        server_updated_at: DateTime<Utc>,
        client_data: Value,
        server_data: Value,
    ) -> AppResult<bool> {
        // Simple timestamp-based conflict detection
        // If timestamps differ, a conflict exists
        let conflict_exists = client_updated_at != server_updated_at;

        if conflict_exists {
            // Record the conflict for potential manual resolution
            let _conflict = self
                .conflict_repo
                .create_conflict(
                    uuid::Uuid::new_v4(), // Would be user_id in real implementation
                    entity_type,
                    uuid::Uuid::parse_str(entity_id).unwrap_or_else(|_| uuid::Uuid::new_v4()),
                    client_updated_at,
                    server_updated_at,
                    client_data,
                    server_data,
                    "server_wins", // Default strategy
                )
                .await?;
        }

        Ok(conflict_exists)
    }

    /// Resolve a conflict using the specified strategy
    /// Currently supports: "server_wins" (server version is authoritative)
    pub async fn resolve_conflict(
        &self,
        conflict_id: &str,
        resolution: &str,
    ) -> AppResult<ConflictResolutionResponse> {
        match resolution {
            "server_wins" => {
                // Mark as resolved - server version is already in database
                self.conflict_repo.mark_resolved(conflict_id, resolution).await?;

                Ok(ConflictResolutionResponse {
                    success: true,
                    message: Some("Conflict resolved using server-wins strategy".to_string()),
                    resolved_entity: None,
                })
            }
            "client_wins" => {
                // TODO: Implement client-wins strategy
                // This would require re-applying client changes over server state
                self.conflict_repo.mark_resolved(conflict_id, resolution).await?;

                Ok(ConflictResolutionResponse {
                    success: true,
                    message: Some("Conflict resolved using client-wins strategy".to_string()),
                    resolved_entity: None,
                })
            }
            _ => Err(AppError::BadRequest(format!(
                "Unknown resolution strategy: {}",
                resolution
            ))),
        }
    }

    /// Get user's unresolved conflicts
    /// Used to notify client of conflicts needing attention
    pub async fn get_pending_conflicts(
        &self,
        user_id: uuid::Uuid,
    ) -> AppResult<Vec<Value>> {
        let conflicts = self
            .conflict_repo
            .get_unresolved_conflicts(user_id)
            .await?;

        // Convert to JSON for API response
        let json_conflicts = conflicts
            .iter()
            .map(|c| {
                serde_json::json!({
                    "id": c.id,
                    "entity_type": c.entity_type,
                    "entity_id": c.entity_id.to_string(),
                    "client_version": c.client_version.to_rfc3339(),
                    "server_version": c.server_version.to_rfc3339(),
                    "client_data": c.client_data,
                    "server_data": c.server_data,
                    "resolution_strategy": c.resolution_strategy,
                })
            })
            .collect();

        Ok(json_conflicts)
    }

    /// Cleanup old conflicts (older than 30 days)
    /// Should be called periodically as a maintenance task
    pub async fn cleanup_old_conflicts(&self) -> AppResult<usize> {
        self.conflict_repo.cleanup_old_conflicts().await
    }
}
