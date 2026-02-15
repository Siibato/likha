use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::change_log;
use crate::utils::{AppError, AppResult};

pub struct ChangeLogRepository {
    db: DatabaseConnection,
}

impl ChangeLogRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    /// Log a change to the change_log table
    pub async fn log_change(
        &self,
        entity_type: &str,
        entity_id: Uuid,
        operation: &str,
        performed_by: Uuid,
        payload: Option<String>,
    ) -> AppResult<change_log::Model> {
        let log = change_log::ActiveModel {
            sequence: NotSet,
            id: Set(Uuid::new_v4()),
            entity_type: Set(entity_type.to_string()),
            entity_id: Set(entity_id.to_string()),
            operation: Set(operation.to_string()),
            performed_by: Set(performed_by),
            payload: Set(payload),
            created_at: Set(Utc::now().naive_utc()),
        };

        log.insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create change log: {}", e)))
    }

    /// Find all changes since a given sequence number
    /// Returns up to `limit` entries (default 500, max 1000)
    pub async fn find_since(
        &self,
        since_sequence: i64,
        limit: u64,
    ) -> AppResult<Vec<change_log::Model>> {
        let effective_limit = std::cmp::min(limit, 1000);

        change_log::Entity::find()
            .filter(change_log::Column::Sequence.gt(since_sequence))
            .order_by_asc(change_log::Column::Sequence)
            .limit(effective_limit)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    /// Get the latest sequence number in the change_log
    pub async fn get_latest_sequence(&self) -> AppResult<i64> {
        change_log::Entity::find()
            .order_by_desc(change_log::Column::Sequence)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
            .map(|opt| opt.map(|model| model.sequence).unwrap_or(0))
    }

    /// Check if there are more changes after the given sequence
    pub async fn has_more(&self, since_sequence: i64, limit: u64) -> AppResult<bool> {
        let effective_limit = std::cmp::min(limit, 1000);

        let count = change_log::Entity::find()
            .filter(change_log::Column::Sequence.gt(since_sequence))
            .limit(effective_limit + 1)
            .count(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(count > effective_limit as u64)
    }
}
