use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;
use sea_orm::{ConnectionTrait, Statement, DbBackend, DatabaseConnection};

use crate::services::sync_push::OperationResult;

pub async fn check_processed(
    db: &DatabaseConnection,
    cache: &Arc<RwLock<HashMap<String, (Uuid, OperationResult)>>>,
    operation_id: &str,
) -> Result<Option<OperationResult>, String> {
    // Fast path: check RAM cache first
    {
        let cache = cache.read().await;
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

    match db.query_one(statement).await {
        Ok(Some(row)) => {
            let response_json = row.try_get::<String>("", "response")
                .map_err(|e| format!("Failed to parse response: {}", e))?;
            match serde_json::from_str::<OperationResult>(&response_json) {
                Ok(result) => {
                    // Warm the RAM cache for future checks
                    let mut cache = cache.write().await;
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
