use chrono::Utc;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::sync_conflicts;

/// A detected conflict between client and server versions
#[derive(Debug, Clone)]
pub struct SyncConflict {
    pub id: String,
    pub user_id: Uuid,
    pub entity_type: String,
    pub entity_id: Uuid,
    pub client_updated_at: Option<chrono::NaiveDateTime>,
    pub server_updated_at: Option<chrono::NaiveDateTime>,
    pub client_data: Option<Value>,
    pub server_data: Option<Value>,
    pub resolution: Option<String>,
    pub resolved_at: Option<chrono::NaiveDateTime>,
    pub created_at: chrono::NaiveDateTime,
}

/// Repository for tracking and resolving conflicts
#[derive(Clone)]
pub struct SyncConflictRepository {
    db: DatabaseConnection,
}

impl SyncConflictRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    /// Record a detected conflict
    pub async fn create_conflict(
        &self,
        user_id: Uuid,
        entity_type: &str,
        entity_id: Uuid,
        client_updated_at: Option<chrono::NaiveDateTime>,
        server_updated_at: Option<chrono::NaiveDateTime>,
        client_data: Option<Value>,
        server_data: Option<Value>,
    ) -> AppResult<SyncConflict> {
        let conflict_id = uuid::Uuid::new_v4().to_string();
        let now = Utc::now().naive_utc();

        let conflict = sync_conflicts::ActiveModel {
            id: ActiveValue::Set(conflict_id.clone()),
            user_id: ActiveValue::Set(user_id.to_string()),
            entity_type: ActiveValue::Set(entity_type.to_string()),
            entity_id: ActiveValue::Set(entity_id.to_string()),
            client_updated_at: ActiveValue::Set(client_updated_at),
            server_updated_at: ActiveValue::Set(server_updated_at),
            client_data: ActiveValue::Set(client_data.as_ref().map(|v| v.to_string())),
            server_data: ActiveValue::Set(server_data.as_ref().map(|v| v.to_string())),
            resolution: ActiveValue::Set(None),
            resolved_at: ActiveValue::Set(None),
            created_at: ActiveValue::Set(now),
        };

        conflict
            .insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create conflict: {}", e)))?;

        Ok(SyncConflict {
            id: conflict_id,
            user_id,
            entity_type: entity_type.to_string(),
            entity_id,
            client_updated_at,
            server_updated_at,
            client_data,
            server_data,
            resolution: None,
            resolved_at: None,
            created_at: now,
        })
    }

    /// Get unresolved conflicts for a user
    pub async fn get_unresolved_conflicts(&self, user_id: Uuid) -> AppResult<Vec<SyncConflict>> {
        let records = sync_conflicts::Entity::find()
            .filter(sync_conflicts::Column::UserId.eq(user_id.to_string()))
            .filter(sync_conflicts::Column::ResolvedAt.is_null())
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(records
            .into_iter()
            .map(|r| SyncConflict {
                id: r.id,
                user_id: Uuid::parse_str(&r.user_id).unwrap_or_else(|_| Uuid::nil()),
                entity_type: r.entity_type,
                entity_id: Uuid::parse_str(&r.entity_id).unwrap_or_else(|_| Uuid::nil()),
                client_updated_at: r.client_updated_at,
                server_updated_at: r.server_updated_at,
                client_data: r.client_data.and_then(|s| serde_json::from_str(&s).ok()),
                server_data: r.server_data.and_then(|s| serde_json::from_str(&s).ok()),
                resolution: r.resolution,
                resolved_at: r.resolved_at,
                created_at: r.created_at,
            })
            .collect())
    }

    /// Get conflicts for a specific entity
    pub async fn get_entity_conflicts(
        &self,
        user_id: Uuid,
        entity_type: &str,
        entity_id: Uuid,
    ) -> AppResult<Vec<SyncConflict>> {
        let records = sync_conflicts::Entity::find()
            .filter(sync_conflicts::Column::UserId.eq(user_id.to_string()))
            .filter(sync_conflicts::Column::EntityType.eq(entity_type))
            .filter(sync_conflicts::Column::EntityId.eq(entity_id.to_string()))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(records
            .into_iter()
            .map(|r| SyncConflict {
                id: r.id,
                user_id: Uuid::parse_str(&r.user_id).unwrap_or_else(|_| Uuid::nil()),
                entity_type: r.entity_type,
                entity_id: Uuid::parse_str(&r.entity_id).unwrap_or_else(|_| Uuid::nil()),
                client_updated_at: r.client_updated_at,
                server_updated_at: r.server_updated_at,
                client_data: r.client_data.and_then(|s| serde_json::from_str(&s).ok()),
                server_data: r.server_data.and_then(|s| serde_json::from_str(&s).ok()),
                resolution: r.resolution,
                resolved_at: r.resolved_at,
                created_at: r.created_at,
            })
            .collect())
    }

    /// Mark conflict as resolved
    pub async fn mark_resolved(&self, conflict_id: &str, resolution: &str) -> AppResult<()> {
        let now = Utc::now().naive_utc();

        sync_conflicts::Entity::update(sync_conflicts::ActiveModel {
            id: ActiveValue::Unchanged(conflict_id.to_string()),
            resolution: ActiveValue::Set(Some(resolution.to_string())),
            resolved_at: ActiveValue::Set(Some(now)),
            ..Default::default()
        })
        .exec(&self.db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to mark conflict as resolved: {}", e)))?;

        Ok(())
    }

    /// Cleanup resolved conflicts older than 30 days
    pub async fn cleanup_old_conflicts(&self) -> AppResult<usize> {
        let cutoff = Utc::now().naive_utc() - chrono::Duration::days(30);

        let result = sync_conflicts::Entity::delete_many()
            .filter(sync_conflicts::Column::ResolvedAt.lt(cutoff))
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to cleanup conflicts: {}", e)))?;

        Ok(result.rows_affected as usize)
    }
}
