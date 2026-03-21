use uuid::Uuid;
use chrono::Utc;
use crate::schema::auth_schema::{CreateAccountRequest, UpdateAccountRequest, ResetAccountRequest, LockAccountRequest};
use super::sync_push_service::{OperationResult, SyncQueueEntry};
use super::extract_field;

impl super::SyncPushService {
    pub(super) async fn handle_admin_user_operation(&self, user_id: Uuid, op: &SyncQueueEntry) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let username = extract_field!(self, op, parse_str_field, "username");
                let full_name = extract_field!(self, op, parse_str_field, "full_name");
                let role = extract_field!(self, op, parse_str_field, "role");
                let client_id = self.parse_uuid_field(&op.payload, "id").ok();
                let request = CreateAccountRequest { username, full_name, role };
                match self.auth_service.create_account(request, user_id, client_id).await {
                    Ok(u) => self.success_result(op, Some(u.id.to_string()), Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let target_user_id = extract_field!(self, op, parse_uuid_field, "id");
                let action = op.payload.get("action").and_then(|v| v.as_str()).unwrap_or("update");

                match action {
                    "update" => {
                        let request = UpdateAccountRequest {
                            full_name: op.payload.get("full_name").and_then(|v| v.as_str()).map(|s| s.to_string()),
                            role: op.payload.get("role").and_then(|v| v.as_str()).map(|s| s.to_string()),
                        };
                        match self.auth_service.update_account(target_user_id, request, user_id).await {
                            Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                            Err(e) => self.error_result(op, &e.to_string()),
                        }
                    }
                    "reset" => {
                        match self.auth_service.reset_account(ResetAccountRequest { user_id: target_user_id }, user_id).await {
                            Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                            Err(e) => self.error_result(op, &e.to_string()),
                        }
                    }
                    "lock" => {
                        let locked = op.payload.get("locked").and_then(|v| v.as_bool()).unwrap_or(true);
                        let reason = op.payload.get("reason").and_then(|v| v.as_str()).map(|s| s.to_string());
                        match self.auth_service.lock_account(LockAccountRequest { user_id: target_user_id, locked, reason }, user_id).await {
                            Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                            Err(e) => self.error_result(op, &e.to_string()),
                        }
                    }
                    _ => self.error_result(op, &format!("Unknown action for admin_user update: {}", action)),
                }
            }
            _ => self.error_result(op, &format!("Unsupported operation for admin_user: {}", op.operation)),
        }
    }
}