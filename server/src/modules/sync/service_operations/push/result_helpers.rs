use super::sync_push_service::{OperationResult, SyncQueueEntry};

pub fn error_result(op: &SyncQueueEntry, message: &str) -> OperationResult {
    OperationResult {
        id: op.id.clone(),
        entity_type: op.entity_type.clone(),
        operation: op.operation.clone(),
        success: false,
        server_id: None,
        error: Some(message.to_string()),
        updated_at: None,
        metadata: None,
    }
}

pub fn success_result(
    op: &SyncQueueEntry,
    server_id: Option<String>,
    updated_at: Option<String>,
) -> OperationResult {
    OperationResult {
        id: op.id.clone(),
        entity_type: op.entity_type.clone(),
        operation: op.operation.clone(),
        success: true,
        server_id,
        error: None,
        updated_at,
        metadata: None,
    }
}

pub fn parse_uuid_field(payload: &serde_json::Value, field: &str) -> Result<uuid::Uuid, String> {
    payload
        .get(field)
        .and_then(|v| v.as_str())
        .ok_or_else(|| format!("Missing {} field", field))
        .and_then(|s| uuid::Uuid::parse_str(s).map_err(|_| format!("Invalid {}", field)))
}

pub fn parse_str_field(
    payload: &serde_json::Value,
    field: &str,
) -> Result<String, String> {
    payload
        .get(field)
        .and_then(|v| v.as_str())
        .ok_or_else(|| format!("Missing {} field", field))
        .map(String::from)
}

pub fn parse_i32_field(
    payload: &serde_json::Value,
    field: &str,
) -> Result<i32, String> {
    payload
        .get(field)
        .and_then(|v| v.as_i64())
        .ok_or_else(|| format!("Missing {} field", field))
        .map(|v| v as i32)
}
