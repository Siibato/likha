use chrono::{Duration, Utc};
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::sync_cursors;

/// Cursor for resumable pagination (expires after 24h)
#[derive(Debug, Clone)]
pub struct SyncCursorRecord {
    pub id: String,
    pub user_id: Uuid,
    pub entity_type: String,
    pub offset: i64,
    pub expires_at: chrono::NaiveDateTime,
    pub created_at: chrono::NaiveDateTime,
}

/// Repository for managing sync pagination cursors
#[derive(Clone)]
pub struct SyncCursorRepository {
    db: DatabaseConnection,
}

impl SyncCursorRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    /// Create a new cursor for pagination
    /// Returns the cursor ID (opaque string)
    pub async fn create_cursor(
        &self,
        user_id: Uuid,
        entity_type: &str,
        offset: i64,
    ) -> AppResult<String> {
        let cursor_id = uuid::Uuid::new_v4().to_string();
        let now = Utc::now();
        let expires_at = now + Duration::days(1);

        // Convert UTC to NaiveDateTime (removing timezone info for SQLite storage)
        let created_at_naive = now.naive_utc();
        let expires_at_naive = expires_at.naive_utc();

        let cursor = sync_cursors::ActiveModel {
            id: ActiveValue::Set(cursor_id.clone()),
            user_id: ActiveValue::Set(user_id.to_string()),
            entity_type: ActiveValue::Set(entity_type.to_string()),
            offset: ActiveValue::Set(offset),
            created_at: ActiveValue::Set(created_at_naive),
            expires_at: ActiveValue::Set(expires_at_naive),
        };

        cursor
            .insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create cursor: {}", e)))?;

        Ok(cursor_id)
    }

    /// Get cursor data by ID
    pub async fn get_cursor(&self, cursor_id: &str) -> AppResult<Option<SyncCursorRecord>> {
        let record = sync_cursors::Entity::find_by_id(cursor_id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(record.map(|r| SyncCursorRecord {
            id: r.id,
            user_id: Uuid::parse_str(&r.user_id)
                .unwrap_or_else(|_| Uuid::nil()),
            entity_type: r.entity_type,
            offset: r.offset,
            expires_at: r.expires_at,
            created_at: r.created_at,
        }))
    }

    /// Update cursor offset (advance pagination)
    pub async fn update_cursor(&self, cursor_id: &str, new_offset: i64) -> AppResult<()> {
        sync_cursors::Entity::update(sync_cursors::ActiveModel {
            id: ActiveValue::Unchanged(cursor_id.to_string()),
            offset: ActiveValue::Set(new_offset),
            ..Default::default()
        })
        .exec(&self.db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update cursor: {}", e)))?;

        Ok(())
    }

    /// Delete expired cursors (cleanup job)
    pub async fn cleanup_expired(&self) -> AppResult<usize> {
        let now = Utc::now().naive_utc();

        let result = sync_cursors::Entity::delete_many()
            .filter(sync_cursors::Column::ExpiresAt.lt(now))
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to cleanup cursors: {}", e)))?;

        Ok(result.rows_affected as usize)
    }

    /// Check if cursor is still valid
    pub async fn is_cursor_valid(&self, cursor_id: &str) -> AppResult<bool> {
        match self.get_cursor(cursor_id).await? {
            Some(cursor) => {
                let now = Utc::now().naive_utc();
                Ok(cursor.expires_at > now)
            }
            None => Ok(false),
        }
    }
}
