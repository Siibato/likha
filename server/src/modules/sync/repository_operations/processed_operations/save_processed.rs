use sea_orm::{ConnectionTrait, DatabaseConnection, DbBackend, Statement};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;

use crate::modules::sync::service_operations::push::OperationResult;

pub async fn save_processed(
    db: &DatabaseConnection,
    cache: &Arc<RwLock<HashMap<String, (Uuid, OperationResult)>>>,
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
            sea_orm::Value::Uuid(Some(Box::new(user_id))),
            entity_type.to_string().into(),
            operation.to_string().into(),
            response_json.clone().into(),
        ],
    );

    if let Err(e) = db.execute(statement).await {
        return Err(format!("Failed to insert processed operation: {}", e));
    }

    // Update RAM cache
    let mut cache = cache.write().await;
    cache.insert(operation_id.to_string(), (user_id, result.clone()));

    // Run cleanup: remove old entries (older than 30 days)
    let cleanup_sql =
        "DELETE FROM processed_operations WHERE created_at < datetime('now', '-30 days')";
    let cleanup_statement = Statement::from_sql_and_values(DbBackend::Sqlite, cleanup_sql, []);
    let _ = db.execute(cleanup_statement).await;

    Ok(())
}
