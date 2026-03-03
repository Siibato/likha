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
                    Some(client_updated_at.naive_utc()),
                    Some(server_updated_at.naive_utc()),
                    Some(client_data),
                    Some(server_data),
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
                // Fetch the stored conflict record to retrieve the client-side snapshot
                let record = self
                    .conflict_repo
                    .get_conflict_by_id(conflict_id)
                    .await?
                    .ok_or_else(|| AppError::NotFound("Conflict not found".to_string()))?;

                // Parse the stored TEXT → serde_json::Value (same pattern as get_unresolved_conflicts)
                let client_data: Option<Value> = record.client_data;

                self.conflict_repo.mark_resolved(conflict_id, resolution).await?;

                Ok(ConflictResolutionResponse {
                    success: true,
                    message: Some("Conflict resolved: client data restored".to_string()),
                    resolved_entity: client_data,
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
                    "client_updated_at": c.client_updated_at.map(|dt| dt.to_string()),
                    "server_updated_at": c.server_updated_at.map(|dt| dt.to_string()),
                    "client_data": c.client_data,
                    "server_data": c.server_data,
                    "resolution": c.resolution.clone(),
                    "created_at": c.created_at.to_string(),
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
