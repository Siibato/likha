use uuid::Uuid;
use serde_json::Value;
use chrono::Utc;
use crate::utils::AppResult;
use super::sync_push_service::{PushResponse, OperationResult, SyncQueueEntry};

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

        let mut results = Vec::new();

        for op in operations {
            if let Ok(Some(cached_result)) = self.processed_ops_repo.check_processed(&op.id).await {
                results.push(cached_result);
                continue;
            }

            let result = self.process_single_operation(user_id, user_role, &op).await;

            let _ = self.processed_ops_repo.save_processed(
                &op.id,
                user_id,
                &op.entity_type,
                &op.operation,
                &result,
            ).await;

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
        let class_id = op.payload.get("class_id")
            .and_then(|v| v.as_str())
            .and_then(|s| uuid::Uuid::parse_str(s).ok());

        if let Err(_) = self.entitlement_service
            .assert_can_sync_operation(user_id, user_role, &op.operation, &op.entity_type, class_id)
            .await
        {
            return self.error_result(op, "Authorization failed");
        }

        match op.entity_type.as_str() {
            "class" => self.handle_class_operation(user_id, op).await,
            "admin_user" => self.handle_admin_user_operation(user_id, op).await,
            "assessment" => self.handle_assessment_operation(user_id, user_role, op).await,
            "question" => self.handle_question_operation(user_id, op).await,
            "assignment" => self.handle_assignment_operation(user_id, user_role, op).await,
            "learning_material" => self.handle_learning_material_operation(user_id, op).await,
            "assessment_submission" => self.handle_assessment_submission_operation(user_id, op).await,
            "assignment_submission" => self.handle_assignment_submission_operation(user_id, op).await,
            "submission_file" => self.handle_submission_file_operation(user_id, op).await,
            "material_file" => self.handle_material_file_operation(user_id, op).await,
            "activity_log" => self.handle_activity_log_operation(user_id, op).await,
            _ => self.error_result(op, &format!("Unknown entity type: {}", op.entity_type)),
        }
    }

    /// Convenience method to build an error OperationResult
    pub(super) fn error_result(&self, op: &SyncQueueEntry, message: &str) -> OperationResult {
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

    /// Convenience method to build a success OperationResult
    pub(super) fn success_result(
        &self,
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
}

impl super::SyncPushService {
    pub(super) fn parse_uuid_field(&self, payload: &serde_json::Value, field: &str) -> Result<uuid::Uuid, String> {
        payload.get(field)
            .and_then(|v| v.as_str())
            .ok_or_else(|| format!("Missing {} field", field))
            .and_then(|s| uuid::Uuid::parse_str(s).map_err(|_| format!("Invalid {}", field)))
    }
}