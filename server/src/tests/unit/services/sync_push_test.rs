//! Unit tests for SyncPushService pure logic:
//! - SyncQueueEntry deserialization from JSON payload
//! - OperationResult construction and serialization
//!
//! Note: Mock-based tests for service-level push_operations require
//! `mockall = "0.13"` to be vendored. Those tests are pending.

use crate::services::sync_push::sync_push_service::{SyncQueueEntry, OperationResult, PushResponse};

#[test]
fn test_sync_queue_entry_deserializes_from_json() {
    let json = serde_json::json!({
        "id": "op-1",
        "entity_type": "assignment",
        "operation": "create",
        "payload": { "title": "HW 1" }
    });

    let entry: SyncQueueEntry = serde_json::from_value(json).unwrap();
    assert_eq!(entry.id, "op-1");
    assert_eq!(entry.entity_type, "assignment");
    assert_eq!(entry.operation, "create");
}

#[test]
fn test_sync_queue_entry_empty_operations_list_parses_as_empty_vec() {
    let json = serde_json::json!({ "operations": [] });

    let ops: Vec<SyncQueueEntry> = match json.get("operations") {
        Some(ops) => serde_json::from_value(ops.clone()).unwrap_or_default(),
        None => vec![],
    };

    assert!(ops.is_empty());
}

#[test]
fn test_sync_queue_entry_missing_operations_key_yields_empty_vec() {
    let json = serde_json::json!({});

    let ops: Vec<SyncQueueEntry> = match json.get("operations") {
        Some(ops) => serde_json::from_value(ops.clone()).unwrap_or_default(),
        None => vec![],
    };

    assert!(ops.is_empty());
}

#[test]
fn test_sync_queue_entry_multiple_entries() {
    let json = serde_json::json!({
        "operations": [
            { "id": "op-1", "entity_type": "assignment", "operation": "create", "payload": {} },
            { "id": "op-2", "entity_type": "grade_score", "operation": "save_scores", "payload": {} },
            { "id": "op-3", "entity_type": "assessment", "operation": "delete", "payload": {} }
        ]
    });

    let ops: Vec<SyncQueueEntry> = match json.get("operations") {
        Some(ops) => serde_json::from_value(ops.clone()).unwrap_or_default(),
        None => vec![],
    };

    assert_eq!(ops.len(), 3);
    assert_eq!(ops[0].id, "op-1");
    assert_eq!(ops[1].entity_type, "grade_score");
    assert_eq!(ops[2].operation, "delete");
}

#[test]
fn test_operation_result_success_serializes_without_error() {
    let result = OperationResult {
        id: "op-1".to_string(),
        entity_type: "assignment".to_string(),
        operation: "create".to_string(),
        success: true,
        server_id: Some("srv-abc".to_string()),
        error: None,
        updated_at: Some("2025-01-01T00:00:00Z".to_string()),
        metadata: None,
    };

    let json = serde_json::to_value(&result).unwrap();
    assert_eq!(json["success"], true);
    assert!(json.get("error").is_none() || json["error"].is_null());
    assert_eq!(json["server_id"], "srv-abc");
}

#[test]
fn test_operation_result_failure_has_error_field() {
    let result = OperationResult {
        id: "op-2".to_string(),
        entity_type: "grade_score".to_string(),
        operation: "save_scores".to_string(),
        success: false,
        server_id: None,
        error: Some("Grade item not found".to_string()),
        updated_at: None,
        metadata: None,
    };

    let json = serde_json::to_value(&result).unwrap();
    assert_eq!(json["success"], false);
    assert_eq!(json["error"], "Grade item not found");
}

#[test]
fn test_push_response_results_vec_round_trips() {
    let response = PushResponse {
        results: vec![
            OperationResult {
                id: "op-1".to_string(),
                entity_type: "assignment".to_string(),
                operation: "create".to_string(),
                success: true,
                server_id: None,
                error: None,
                updated_at: None,
                metadata: None,
            },
        ],
    };

    let json = serde_json::to_value(&response).unwrap();
    assert_eq!(json["results"].as_array().unwrap().len(), 1);
    assert_eq!(json["results"][0]["id"], "op-1");
}

#[test]
fn test_operation_result_metadata_omitted_when_none() {
    let result = OperationResult {
        id: "op-3".to_string(),
        entity_type: "tos".to_string(),
        operation: "create_tos".to_string(),
        success: true,
        server_id: Some("srv-123".to_string()),
        error: None,
        updated_at: None,
        metadata: None,
    };

    let json = serde_json::to_string(&result).unwrap();
    // metadata has skip_serializing_if = "Option::is_none"
    assert!(!json.contains("metadata"));
}
