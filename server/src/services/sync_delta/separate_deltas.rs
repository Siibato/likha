use serde_json::Value;
use super::sync_delta_service::EntityDeltas;

/// Partitions records into updated and soft-deleted based on the `deleted_at` field.
/// Records with non-null `deleted_at` → `deleted` list (by ID only).
/// All others → `updated` list (full JSON).
pub fn separate_deltas(records: Vec<Value>) -> EntityDeltas {
    let mut updated = Vec::new();
    let mut deleted = Vec::new();

    for record in records {
        let deleted_at = record.get("deleted_at");
        let id = record
            .get("id")
            .and_then(|v| v.as_str())
            .unwrap_or("unknown");

        if let Some(deleted_at_val) = deleted_at {
            if !deleted_at_val.is_null() {
                // This is a soft-deleted record
                deleted.push(id.to_string());
                continue;
            }
        }
        // This is an updated record
        updated.push(record);
    }

    EntityDeltas { updated, deleted }
}
