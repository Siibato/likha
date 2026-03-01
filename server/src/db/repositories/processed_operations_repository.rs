use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;
use sea_orm::{ConnectionTrait, Statement, DbBackend};

use crate::services::sync_push::OperationResult;

/// Repository for tracking processed sync operations
/// Enables deduplication - prevents processing same operation twice
/// Uses in-memory cache for fast access, backed by persistent DB storage
pub struct ProcessedOperationsRepository {
    db: sea_orm::DatabaseConnection,
    cache: Arc<RwLock<HashMap<String, (Uuid, OperationResult)>>>,
}

impl ProcessedOperationsRepository {
    pub fn new(db: sea_orm::DatabaseConnection) -> Self {
        Self {
            db,
            cache: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Check if operation was already processed
    /// Returns cached result if found, None if new operation
    /// First checks RAM cache (fast path), then queries DB if not found in cache
    pub async fn check_processed(
        &self,
        operation_id: &str,
    ) -> Result<Option<OperationResult>, String> {
        // Fast path: check RAM cache first
        {
            let cache = self.cache.read().await;
            if let Some((_, result)) = cache.get(operation_id) {
                return Ok(Some(result.clone()));
            }
        }

        // Slow path: check persistent DB
        let sql = "SELECT response FROM processed_operations WHERE operation_id = ? LIMIT 1";
        let statement = Statement::from_sql_and_values(
            DbBackend::Sqlite,
            sql,
            [operation_id.to_string().into()],
        );

        match self.db.query_one(statement).await {
            Ok(Some(row)) => {
                let response_json = row.try_get::<String>("", "response")
                    .map_err(|e| format!("Failed to parse response: {}", e))?;
                match serde_json::from_str::<OperationResult>(&response_json) {
                    Ok(result) => {
                        // Warm the RAM cache for future checks
                        let mut cache = self.cache.write().await;
                        cache.insert(operation_id.to_string(), (Uuid::nil(), result.clone()));
                        Ok(Some(result))
                    }
                    Err(e) => Err(format!("Failed to deserialize operation result: {}", e)),
                }
            }
            Ok(None) => Ok(None),
            Err(e) => Err(format!("Database query failed: {}", e)),
        }
    }

    /// Save operation result after processing
    /// Allows deduplication on retry - persists to both RAM and DB
    pub async fn save_processed(
        &self,
        operation_id: &str,
        user_id: Uuid,
        entity_type: &str,
        operation: &str,
        result: &OperationResult,
    ) -> Result<(), String> {
        let response_json = serde_json::to_string(result)
            .map_err(|e| format!("Failed to serialize operation result: {}", e))?;

        let id = Uuid::new_v4().to_string();

        // Save to persistent DB
        let sql = r#"
            INSERT OR IGNORE INTO processed_operations
            (id, operation_id, user_id, entity_type, operation, response, created_at)
            VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
        "#;

        let statement = Statement::from_sql_and_values(
            DbBackend::Sqlite,
            sql,
            [
                id.into(),
                operation_id.to_string().into(),
                user_id.to_string().into(),
                entity_type.to_string().into(),
                operation.to_string().into(),
                response_json.clone().into(),
            ],
        );

        if let Err(e) = self.db.execute(statement).await {
            return Err(format!("Failed to insert processed operation: {}", e));
        }

        // Update RAM cache
        let mut cache = self.cache.write().await;
        cache.insert(operation_id.to_string(), (user_id, result.clone()));

        // Run cleanup: remove old entries (older than 30 days)
        let cleanup_sql = "DELETE FROM processed_operations WHERE created_at < datetime('now', '-30 days')";
        let cleanup_statement = Statement::from_sql_and_values(DbBackend::Sqlite, cleanup_sql, []);
        let _ = self.db.execute(cleanup_statement).await;

        Ok(())
    }

    /// Cleanup old processed operations (maintenance task)
    /// Call periodically to manage cache and DB size
    pub async fn cleanup_old_operations(&self, days_old: i32) -> Result<u64, String> {
        // Clear RAM cache
        let mut cache = self.cache.write().await;
        let count = cache.len() as u64;
        cache.clear();

        // Delete old entries from DB
        let sql = format!(
            "DELETE FROM processed_operations WHERE created_at < datetime('now', '-{} days')",
            days_old
        );
        let statement = Statement::from_sql_and_values(DbBackend::Sqlite, &sql, []);

        self.db.execute(statement).await
            .map_err(|e| format!("Cleanup failed: {}", e))?;

        Ok(count)
    }
}
