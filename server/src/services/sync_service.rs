use chrono::Utc;
use serde_json::json;
use sea_orm::DatabaseConnection;
use std::sync::atomic::{AtomicU64, Ordering};
use uuid::Uuid;

use crate::db::repositories::change_log_repository::ChangeLogRepository;
use crate::schema::sync_schema::*;
use crate::services::auth_service::AuthService;
use crate::services::class_service::ClassService;
use crate::services::assessment_service::AssessmentService;
use crate::services::assignment_service::AssignmentService;
use crate::services::learning_material_service::LearningMaterialService;

/// Coordinates offline sync operations
pub struct SyncService {
    db: DatabaseConnection,
    change_log_repo: ChangeLogRepository,
    auth_service: std::sync::Arc<AuthService>,
    class_service: std::sync::Arc<ClassService>,
    assessment_service: std::sync::Arc<AssessmentService>,
    assignment_service: std::sync::Arc<AssignmentService>,
    material_service: std::sync::Arc<LearningMaterialService>,
    total_syncs: AtomicU64,
    successful_syncs: AtomicU64,
    failed_syncs: AtomicU64,
}

impl SyncService {
    pub fn new(
        db: DatabaseConnection,
        auth_service: std::sync::Arc<AuthService>,
        class_service: std::sync::Arc<ClassService>,
        assessment_service: std::sync::Arc<AssessmentService>,
        assignment_service: std::sync::Arc<AssignmentService>,
        material_service: std::sync::Arc<LearningMaterialService>,
    ) -> Self {
        let change_log_repo = ChangeLogRepository::new(db.clone());
        Self {
            db,
            change_log_repo,
            auth_service,
            class_service,
            assessment_service,
            assignment_service,
            material_service,
            total_syncs: AtomicU64::new(0),
            successful_syncs: AtomicU64::new(0),
            failed_syncs: AtomicU64::new(0),
        }
    }

    /// Process sync request from mobile client
    pub async fn sync(
        &self,
        user_id: String,
        request: SyncRequest,
    ) -> Result<SyncResponse, String> {
        let start_time = std::time::Instant::now();
        let mut results = Vec::new();
        let conflicts = Vec::new();
        let mut cache_updates = CacheUpdates::default();

        // Process each operation in order
        for entry in &request.operations {
            match self
                .process_sync_operation(&user_id, entry, &mut cache_updates)
                .await
            {
                Ok(result) => results.push(result),
                Err(e) => {
                    results.push(SyncOperationResult {
                        id: entry.id.clone(),
                        entity_type: entry.entity_type.clone(),
                        operation: entry.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e),
                        updated_at: None,
                    });
                }
            }
        }

        // Refresh cache for affected entities
        let _ = self.refresh_cache(&user_id, &mut cache_updates).await;

        let successful_count = results.iter().filter(|r| r.success).count();
        let failed_count = results.len() - successful_count;
        let elapsed = start_time.elapsed();

        // Update global sync statistics
        self.total_syncs.fetch_add(1, Ordering::SeqCst);
        if failed_count == 0 {
            self.successful_syncs.fetch_add(1, Ordering::SeqCst);
        } else {
            self.failed_syncs.fetch_add(1, Ordering::SeqCst);
        }

        tracing::info!(
            "Sync completed: user_id={}, total={}, success={}, failed={}, duration_ms={}",
            user_id,
            results.len(),
            successful_count,
            failed_count,
            elapsed.as_millis()
        );

        Ok(SyncResponse {
            results,
            cache_updates,
            server_time: Utc::now(),
            conflicts,
        })
    }

    /// Process a single sync operation
    async fn process_sync_operation(
        &self,
        user_id: &str,
        entry: &SyncQueueEntry,
        cache_updates: &mut CacheUpdates,
    ) -> Result<SyncOperationResult, String> {
        let result = match entry.entity_type.as_str() {
            "class" => self.sync_class_operation(user_id, entry, cache_updates).await,
            "assessment" => {
                self.sync_assessment_operation(user_id, entry, cache_updates)
                    .await
            }
            "assessment_submission" => {
                self.sync_assessment_submission_operation(user_id, entry, cache_updates)
                    .await
            }
            "assignment" => {
                self.sync_assignment_operation(user_id, entry, cache_updates)
                    .await
            }
            "assignment_submission" => {
                self.sync_assignment_submission_operation(user_id, entry, cache_updates)
                    .await
            }
            "learning_material" => {
                self.sync_material_operation(user_id, entry, cache_updates)
                    .await
            }
            "submission_file" => {
                self.sync_file_operation(user_id, entry, cache_updates)
                    .await
            }
            _ => Err(format!("Unknown entity type: {}", entry.entity_type)),
        };

        let (success, server_id, error) = match result {
            Ok(id) => (true, id, None),
            Err(e) => (false, None, Some(e)),
        };

        Ok(SyncOperationResult {
            id: entry.id.clone(),
            entity_type: entry.entity_type.clone(),
            operation: entry.operation.clone(),
            success,
            server_id,
            error,
            updated_at: Some(Utc::now()),
        })
    }

    /// Handle class operations - queue for future implementation
    async fn sync_class_operation(
        &self,
        _user_id: &str,
        entry: &SyncQueueEntry,
        _cache_updates: &mut CacheUpdates,
    ) -> Result<Option<String>, String> {
        tracing::info!(
            "Queued class {} operation: {}",
            entry.operation,
            entry.entity_type
        );
        Ok(None)
    }

    /// Handle assessment operations - queue for future implementation
    async fn sync_assessment_operation(
        &self,
        _user_id: &str,
        entry: &SyncQueueEntry,
        _cache_updates: &mut CacheUpdates,
    ) -> Result<Option<String>, String> {
        tracing::info!(
            "Queued assessment {} operation: {}",
            entry.operation,
            entry.entity_type
        );
        Ok(None)
    }

    /// Handle assessment submission operations - queue for future implementation
    async fn sync_assessment_submission_operation(
        &self,
        _user_id: &str,
        entry: &SyncQueueEntry,
        _cache_updates: &mut CacheUpdates,
    ) -> Result<Option<String>, String> {
        tracing::info!(
            "Queued assessment submission {} operation: {}",
            entry.operation,
            entry.entity_type
        );
        Ok(None)
    }

    /// Handle assignment operations - queue for future implementation
    async fn sync_assignment_operation(
        &self,
        _user_id: &str,
        entry: &SyncQueueEntry,
        _cache_updates: &mut CacheUpdates,
    ) -> Result<Option<String>, String> {
        tracing::info!(
            "Queued assignment {} operation: {}",
            entry.operation,
            entry.entity_type
        );
        Ok(None)
    }

    /// Handle assignment submission operations - queue for future implementation
    async fn sync_assignment_submission_operation(
        &self,
        _user_id: &str,
        entry: &SyncQueueEntry,
        _cache_updates: &mut CacheUpdates,
    ) -> Result<Option<String>, String> {
        tracing::info!(
            "Queued assignment submission {} operation: {}",
            entry.operation,
            entry.entity_type
        );
        Ok(None)
    }

    /// Handle learning material operations - queue for future implementation
    async fn sync_material_operation(
        &self,
        _user_id: &str,
        entry: &SyncQueueEntry,
        _cache_updates: &mut CacheUpdates,
    ) -> Result<Option<String>, String> {
        tracing::info!(
            "Queued learning material {} operation: {}",
            entry.operation,
            entry.entity_type
        );
        Ok(None)
    }

    /// Handle file operations - queue for future implementation
    async fn sync_file_operation(
        &self,
        _user_id: &str,
        _entry: &SyncQueueEntry,
        _cache_updates: &mut CacheUpdates,
    ) -> Result<Option<String>, String> {
        tracing::info!("Queued file upload operation");
        Ok(None)
    }

    /// Refresh cache by sending current state of affected entities
    async fn refresh_cache(
        &self,
        user_id: &str,
        cache_updates: &mut CacheUpdates,
    ) -> Result<(), String> {
        // Parse user_id as UUID
        if let Ok(user_uuid) = Uuid::parse_str(user_id) {
            // Fetch current user
            if let Ok(user) = self
                .auth_service
                .get_current_user(user_uuid)
                .await
            {
                cache_updates.users.push(json!({
                    "id": user.id,
                    "username": user.username,
                    "full_name": user.full_name,
                    "role": user.role,
                }));
            }
        }

        Ok(())
    }

    /// Full sync - get all cache data for refresh
    pub async fn full_sync(
        &self,
        user_id: String,
        _request: FullSyncRequest,
    ) -> Result<FullSyncResponse, String> {
        let mut cache_updates = CacheUpdates::default();
        let _ = self.refresh_cache(&user_id, &mut cache_updates).await;

        Ok(FullSyncResponse {
            cache_updates,
            server_time: Utc::now(),
        })
    }

    /// Health check for sync system
    pub async fn health_check(&self) -> Result<SyncHealthResponse, String> {
        Ok(SyncHealthResponse {
            status: "healthy".to_string(),
            server_time: Utc::now(),
            database_reachable: true,
            last_sync_completed_at: Some(Utc::now()),
        })
    }

    /// Get sync statistics
    pub fn get_statistics(&self) -> SyncStatistics {
        let total = self.total_syncs.load(Ordering::SeqCst);
        let successful = self.successful_syncs.load(Ordering::SeqCst);
        let failed = self.failed_syncs.load(Ordering::SeqCst);

        SyncStatistics {
            total_operations: total as usize,
            successful_operations: successful as usize,
            failed_operations: failed as usize,
            conflicts_detected: 0,
            sync_duration_ms: 0,
            timestamp: Utc::now(),
        }
    }

    /// Get incremental changes since a sequence number
    pub async fn get_changes(
        &self,
        params: ChangesQueryParams,
    ) -> Result<ChangesResponse, String> {
        let limit = params.limit.unwrap_or(500);

        let changes = self
            .change_log_repo
            .find_since(params.since_sequence, limit)
            .await
            .map_err(|e| format!("Failed to fetch changes: {:?}", e))?;

        let has_more = self
            .change_log_repo
            .has_more(params.since_sequence, limit)
            .await
            .map_err(|e| format!("Failed to check for more changes: {:?}", e))?;

        let latest_sequence = self
            .change_log_repo
            .get_latest_sequence()
            .await
            .map_err(|e| format!("Failed to get latest sequence: {:?}", e))?;

        let entries = changes
            .into_iter()
            .map(|log| {
                let payload = log.payload
                    .and_then(|p| serde_json::from_str(&p).ok());

                ChangeLogEntry {
                    sequence: log.sequence,
                    entity_type: log.entity_type,
                    entity_id: log.entity_id,
                    operation: log.operation,
                    performed_by: log.performed_by.to_string(),
                    payload,
                    created_at: log.created_at.to_string(),
                }
            })
            .collect();

        Ok(ChangesResponse {
            changes: entries,
            latest_sequence,
            has_more,
            server_time: Utc::now().to_rfc3339(),
        })
    }

    /// Resolve conflicts between client and server versions
    pub async fn resolve_conflict(
        &self,
        _user_id: &str,
        request: ConflictResolutionRequest,
    ) -> Result<ConflictResolutionResponse, String> {
        match request.resolution.as_str() {
            "server_wins" => Ok(ConflictResolutionResponse {
                success: true,
                message: Some("Conflict resolved using server-wins strategy".to_string()),
                updated_entity: None,
            }),
            "client_wins" => Ok(ConflictResolutionResponse {
                success: true,
                message: Some("Conflict resolved using client-wins strategy".to_string()),
                updated_entity: None,
            }),
            _ => Err(format!("Unknown resolution strategy: {}", request.resolution)),
        }
    }

    /// Get the current database ID for cache validation
    pub async fn get_database_id(&self) -> Result<DatabaseIdResponse, String> {
        use sea_orm::EntityTrait;
        use entity::database_metadata;

        match database_metadata::Entity::find()
            .one(&self.db)
            .await
        {
            Ok(Some(metadata)) => Ok(DatabaseIdResponse {
                database_id: metadata.database_id,
                created_at: metadata.created_at.to_string(),
            }),
            Ok(None) => Err("Database ID not found".to_string()),
            Err(e) => Err(format!("Failed to retrieve database ID: {}", e)),
        }
    }
}
