use super::result_helpers::error_result;
use super::sync_push_service::{OperationResult, PushResponse, SyncQueueEntry};
use crate::utils::AppResult;
use serde_json::Value;
use uuid::Uuid;

impl super::SyncPushService {
    pub async fn push_operations(
        &self,
        user_id: Uuid,
        user_role: &str,
        payload: Value,
    ) -> AppResult<PushResponse> {
        let operations: Vec<SyncQueueEntry> = match payload.get("operations") {
            Some(ops) => serde_json::from_value(ops.clone()).unwrap_or_default(),
            None => vec![],
        };

        // Count operations by entity type for logging
        let mut op_counts: std::collections::HashMap<String, usize> =
            std::collections::HashMap::new();
        for op in &operations {
            *op_counts.entry(op.entity_type.clone()).or_insert(0) += 1;
        }

        let op_summary = op_counts
            .iter()
            .map(|(k, v)| format!("{}={}", k, v))
            .collect::<Vec<_>>()
            .join(", ");

        tracing::debug!(
            "Processing {} operations by type: [{}]",
            operations.len(),
            op_summary
        );

        let mut results = Vec::new();

        for op in operations {
            match self.processed_ops_repo.check_processed(&op.id).await {
                Ok(Some(cached_result)) => {
                    results.push(cached_result);
                    continue;
                }
                Ok(None) => {
                    // Not processed yet, continue to process below
                }
                Err(e) => {
                    // Log the error, but process anyway (fail-open to avoid data loss)
                    tracing::warn!("Failed to check processed operations for {}: {}", op.id, e);
                }
            }

            let result = self.process_single_operation(user_id, user_role, &op).await;

            // Log operation result details
            if !result.success {
                tracing::warn!(
                    "Operation failed: op_id={}, entity_type={}, operation={}, error={}",
                    result.id,
                    result.entity_type,
                    result.operation,
                    result.error.as_deref().unwrap_or("unknown")
                );
            } else {
                tracing::debug!(
                    "Operation succeeded: op_id={}, entity_type={}, operation={}, server_id={}",
                    result.id,
                    result.entity_type,
                    result.operation,
                    result.server_id.as_deref().unwrap_or("none")
                );
            }

            let _ = self
                .processed_ops_repo
                .save_processed(&op.id, user_id, &op.entity_type, &op.operation, &result)
                .await;

            results.push(result);
        }

        Ok(PushResponse { results })
    }

    pub(super) async fn process_single_operation(
        &self,
        user_id: Uuid,
        user_role: &str,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        let class_id = op
            .payload
            .get("class_id")
            .and_then(|v| v.as_str())
            .and_then(|s| uuid::Uuid::parse_str(s).ok());

        if let Err(_) = self
            .entitlement_service
            .assert_can_sync_operation(user_id, user_role, &op.operation, &op.entity_type, class_id)
            .await
        {
            return error_result(op, "Authorization failed");
        }

        for delegate in &self.delegates {
            if delegate.can_handle(&op.entity_type) {
                return delegate.process(user_id, user_role, op).await;
            }
        }

        error_result(op, &format!("Unknown entity type: {}", op.entity_type))
    }
}
