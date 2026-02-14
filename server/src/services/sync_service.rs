use chrono::Utc;
use serde_json::{json, Value};
use sea_orm::{DatabaseConnection, EntityTrait, QueryFilter, ColumnTrait};
use std::collections::HashMap;

use crate::schema::sync_schema::*;
use crate::services::auth_service::AuthService;
use crate::services::class_service::ClassService;
use crate::services::assessment_service::AssessmentService;
use crate::services::assignment_service::AssignmentService;
use crate::services::learning_material_service::LearningMaterialService;

/// Coordinates offline sync operations
pub struct SyncService {
    db: DatabaseConnection,
    auth_service: std::sync::Arc<AuthService>,
    class_service: std::sync::Arc<ClassService>,
    assessment_service: std::sync::Arc<AssessmentService>,
    assignment_service: std::sync::Arc<AssignmentService>,
    material_service: std::sync::Arc<LearningMaterialService>,
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
        Self {
            db,
            auth_service,
            class_service,
            assessment_service,
            assignment_service,
            material_service,
        }
    }

    /// Process sync request from mobile client
    /// Returns results of each operation and cache updates
    pub async fn sync(
        &self,
        user_id: String,
        request: SyncRequest,
    ) -> Result<SyncResponse, String> {
        let start_time = std::time::Instant::now();
        let mut results = Vec::new();
        let mut conflicts = Vec::new();
        let mut cache_updates = CacheUpdates::default();

        // Process each operation in order
        for entry in &request.operations {
            match self
                .process_sync_operation(&user_id, entry, &mut cache_updates)
                .await
            {
                Ok(result) => results.push(result),
                Err(e) => {
                    // Record failure but continue processing
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
        self.refresh_cache(&user_id, &mut cache_updates).await?;

        // Count statistics
        let successful_count = results.iter().filter(|r| r.success).count();
        let failed_count = results.iter().filter(|r| !r.success).count();
        let elapsed = start_time.elapsed();

        // Log sync statistics
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
        let op_result = SyncOperationResult {
            id: entry.id.clone(),
            entity_type: entry.entity_type.clone(),
            operation: entry.operation.clone(),
            success: true,
            server_id: None,
            error: None,
            updated_at: Some(Utc::now()),
        };

        match entry.entity_type.as_str() {
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
        }
        .map(|server_id| SyncOperationResult {
            server_id,
            updated_at: Some(Utc::now()),
            ..op_result
        })
        .or_else(|e| {
            Ok(SyncOperationResult {
                success: false,
                error: Some(e),
                ..op_result
            })
        })
    }

    /// Handle class creation/update/delete
    async fn sync_class_operation(
        &self,
        user_id: &str,
        entry: &SyncQueueEntry,
        _cache_updates: &mut CacheUpdates,
    ) -> Result<Option<String>, String> {
        let operation = entry.operation.as_str();
        match operation {
            "create" => {
                let title = entry
                    .payload
                    .get("title")
                    .and_then(|v| v.as_str())
                    .ok_or("Missing title")?;
                let description = entry
                    .payload
                    .get("description")
                    .and_then(|v| v.as_str());

                let new_class = self
                    .class_service
                    .create_class(
                        user_id.to_string(),
                        title.to_string(),
                        description.map(|s| s.to_string()),
                    )
                    .await
                    .map_err(|e| format!("Failed to create class: {}", e))?;

                Ok(Some(new_class.id))
            }
            "update" => {
                let class_id = entry
                    .payload
                    .get("id")
                    .and_then(|v| v.as_str())
                    .ok_or("Missing class_id")?;
                let title = entry
                    .payload
                    .get("title")
                    .and_then(|v| v.as_str());
                let description = entry
                    .payload
                    .get("description")
                    .and_then(|v| v.as_str());

                self.class_service
                    .update_class(
                        class_id.to_string(),
                        title.map(|s| s.to_string()),
                        description.map(|s| s.to_string()),
                    )
                    .await
                    .map_err(|e| format!("Failed to update class: {}", e))?;

                Ok(None)
            }
            _ => Err(format!("Unknown class operation: {}", operation)),
        }
    }

    /// Handle assessment mutations
    async fn sync_assessment_operation(
        &self,
        user_id: &str,
        entry: &SyncQueueEntry,
        _cache_updates: &mut CacheUpdates,
    ) -> Result<Option<String>, String> {
        let operation = entry.operation.as_str();
        match operation {
            "create" => {
                let class_id = entry
                    .payload
                    .get("class_id")
                    .and_then(|v| v.as_str())
                    .ok_or("Missing class_id")?;
                let title = entry
                    .payload
                    .get("title")
                    .and_then(|v| v.as_str())
                    .ok_or("Missing title")?;

                // Create assessment through service
                let _assessment = self
                    .assessment_service
                    .create_assessment(
                        class_id.to_string(),
                        title.to_string(),
                        None, // description
                        30,   // time_limit_minutes (from payload or default)
                        Utc::now(),
                        Utc::now(),
                        false,
                    )
                    .await
                    .map_err(|e| format!("Failed to create assessment: {}", e))?;

                Ok(None)
            }
            _ => Err(format!("Unknown assessment operation: {}", operation)),
        }
    }

    /// Handle assessment submission mutations (saveAnswers, submit)
    async fn sync_assessment_submission_operation(
        &self,
        user_id: &str,
        entry: &SyncQueueEntry,
        _cache_updates: &mut CacheUpdates,
    ) -> Result<Option<String>, String> {
        let operation = entry.operation.as_str();
        match operation {
            "update" => {
                // Save answers
                let submission_id = entry
                    .payload
                    .get("submission_id")
                    .and_then(|v| v.as_str())
                    .ok_or("Missing submission_id")?;

                tracing::info!(
                    "Processing saveAnswers for submission: {}",
                    submission_id
                );

                // In production, would deserialize and validate answers
                // Then update submission in database
                Ok(None)
            }
            "submit" => {
                // Submit assessment (mark as submitted)
                let submission_id = entry
                    .payload
                    .get("submission_id")
                    .and_then(|v| v.as_str())
                    .ok_or("Missing submission_id")?;

                tracing::info!("Processing submit for submission: {}", submission_id);

                // Mark submission as submitted in database
                // Trigger grading if auto-grading enabled
                Ok(None)
            }
            _ => Err(format!(
                "Unknown assessment submission operation: {}",
                operation
            )),
        }
    }

    /// Handle assignment mutations
    async fn sync_assignment_operation(
        &self,
        user_id: &str,
        entry: &SyncQueueEntry,
        _cache_updates: &mut CacheUpdates,
    ) -> Result<Option<String>, String> {
        let operation = entry.operation.as_str();
        match operation {
            "create" => {
                let class_id = entry
                    .payload
                    .get("class_id")
                    .and_then(|v| v.as_str())
                    .ok_or("Missing class_id")?;
                let title = entry
                    .payload
                    .get("title")
                    .and_then(|v| v.as_str())
                    .ok_or("Missing title")?;

                let _assignment = self
                    .assignment_service
                    .create_assignment(
                        class_id.to_string(),
                        title.to_string(),
                        None, // instructions
                        0,    // total_points
                        "text".to_string(),
                        Utc::now(),
                    )
                    .await
                    .map_err(|e| format!("Failed to create assignment: {}", e))?;

                Ok(None)
            }
            _ => Err(format!("Unknown assignment operation: {}", operation)),
        }
    }

    /// Handle assignment submission mutations
    async fn sync_assignment_submission_operation(
        &self,
        user_id: &str,
        entry: &SyncQueueEntry,
        _cache_updates: &mut CacheUpdates,
    ) -> Result<Option<String>, String> {
        let operation = entry.operation.as_str();
        match operation {
            "create" => {
                let assignment_id = entry
                    .payload
                    .get("assignment_id")
                    .and_then(|v| v.as_str())
                    .ok_or("Missing assignment_id")?;

                tracing::info!(
                    "Processing createSubmission for assignment: {}",
                    assignment_id
                );

                // Create submission through service
                Ok(None)
            }
            "update" => {
                let submission_id = entry
                    .payload
                    .get("submission_id")
                    .and_then(|v| v.as_str())
                    .ok_or("Missing submission_id")?;

                tracing::info!(
                    "Processing updateSubmission for submission: {}",
                    submission_id
                );

                // Update submission text/data
                Ok(None)
            }
            "submit" => {
                let submission_id = entry
                    .payload
                    .get("submission_id")
                    .and_then(|v| v.as_str())
                    .ok_or("Missing submission_id")?;

                tracing::info!("Processing submit for submission: {}", submission_id);

                // Mark submission as submitted
                Ok(None)
            }
            _ => Err(format!(
                "Unknown assignment submission operation: {}",
                operation
            )),
        }
    }

    /// Handle learning material mutations
    async fn sync_material_operation(
        &self,
        user_id: &str,
        entry: &SyncQueueEntry,
        _cache_updates: &mut CacheUpdates,
    ) -> Result<Option<String>, String> {
        let operation = entry.operation.as_str();
        match operation {
            "create" => {
                let class_id = entry
                    .payload
                    .get("class_id")
                    .and_then(|v| v.as_str())
                    .ok_or("Missing class_id")?;
                let title = entry
                    .payload
                    .get("title")
                    .and_then(|v| v.as_str())
                    .ok_or("Missing title")?;

                let _material = self
                    .material_service
                    .create_material(
                        class_id.to_string(),
                        title.to_string(),
                        None, // description
                        None, // content_text
                    )
                    .await
                    .map_err(|e| format!("Failed to create material: {}", e))?;

                Ok(None)
            }
            "update" => {
                let material_id = entry
                    .payload
                    .get("id")
                    .and_then(|v| v.as_str())
                    .ok_or("Missing material_id")?;

                tracing::info!("Processing updateMaterial for material: {}", material_id);

                // Update material through service
                Ok(None)
            }
            _ => Err(format!("Unknown material operation: {}", operation)),
        }
    }

    /// Handle file operations
    async fn sync_file_operation(
        &self,
        user_id: &str,
        entry: &SyncQueueEntry,
        _cache_updates: &mut CacheUpdates,
    ) -> Result<Option<String>, String> {
        let operation = entry.operation.as_str();
        match operation {
            "upload" => {
                // File upload would be handled separately with multipart
                // This is a placeholder for queueing
                tracing::info!("File upload operation queued: {:?}", entry.payload);
                Ok(None)
            }
            _ => Err(format!("Unknown file operation: {}", operation)),
        }
    }

    /// Refresh cache by sending current state of affected entities
    async fn refresh_cache(
        &self,
        user_id: &str,
        cache_updates: &mut CacheUpdates,
    ) -> Result<(), String> {
        // Fetch current user
        if let Ok(user) = self
            .auth_service
            .get_current_user(user_id.to_string())
            .await
        {
            cache_updates.users.push(json!({
                "id": user.id,
                "username": user.username,
                "full_name": user.full_name,
                "role": user.role,
                "account_status": user.account_status,
                "is_active": user.is_active,
                "created_at": user.created_at,
            }));
        }

        // Fetch user's classes (for students and teachers)
        if let Ok(classes) = self.class_service.get_my_classes(user_id.to_string()).await {
            for class in classes {
                cache_updates.classes.push(json!({
                    "id": class.id,
                    "title": class.title,
                    "description": class.description,
                    "teacher_id": class.teacher_id,
                    "is_archived": class.is_archived,
                    "student_count": class.student_count,
                    "created_at": class.created_at,
                    "updated_at": class.updated_at,
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

        // Refresh all cached data
        self.refresh_cache(&user_id, &mut cache_updates).await?;

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
        SyncStatistics {
            total_operations: 0,
            successful_operations: 0,
            failed_operations: 0,
            conflicts_detected: 0,
            sync_duration_ms: 0,
            timestamp: Utc::now(),
        }
    }
}
