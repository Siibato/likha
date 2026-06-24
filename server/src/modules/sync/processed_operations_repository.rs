use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;

use crate::modules::sync::repository_operations::processed_operations as ops;
use crate::modules::sync::service_operations::push::OperationResult;

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
        ops::check_processed(&self.db, &self.cache, operation_id).await
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
        ops::save_processed(
            &self.db,
            &self.cache,
            operation_id,
            user_id,
            entity_type,
            operation,
            result,
        )
        .await
    }
}
