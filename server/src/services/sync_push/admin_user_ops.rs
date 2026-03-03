use uuid::Uuid;
use chrono::Utc;
use crate::schema::auth_schema::{CreateAccountRequest, UpdateAccountRequest, ResetAccountRequest, LockAccountRequest};
use super::sync_push_service::{OperationResult, SyncQueueEntry};

impl super::SyncPushService {
    pub(super) async fn handle_admin_user_operation(&self, user_id: Uuid, op: &SyncQueueEntry) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let username = match op.payload.get("username").and_then(|v| v.as_str()) {
                    Some(u) => u.to_string(),
                    None => return self.error_result(op, "Missing username field"),
                };
                let full_name = match op.payload.get("full_name").and_then(|v| v.as_str()) {
                    Some(n) => n.to_string(),
                    None => return self.error_result(op, "Missing full_name field"),
                };
                let role = match op.payload.get("role").and_then(|v| v.as_str()) {
                    Some(r) => r.to_string(),
                    None => return self.error_result(op, "Missing role field"),
                };
                let request = CreateAccountRequest { username, full_name, role };
                match self.auth_service.create_account(request, user_id).await {
                    Ok(u) => self.success_result(op, Some(u.id.to_string()), Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let target_user_id = match self.parse_uuid_field(&op.payload, "id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                let action = op.payload.get("action").and_then(|v| v.as_str()).unwrap_or("update");

                match action {
                    "update" => {
                        let request = UpdateAccountRequest {
                            username: op.payload.get("username").and_then(|v| v.as_str()).map(|s| s.to_string()),
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
                        match self.auth_service.lock_account(LockAccountRequest { user_id: target_user_id, locked }, user_id).await {
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