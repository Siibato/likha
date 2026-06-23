use super::delegate::PushDelegate;
use super::result_helpers::{error_result, parse_str_field, parse_uuid_field, success_result};
use super::sync_push_service::{OperationResult, SyncQueueEntry};
use crate::modules::admin::schema::{
    CreateAccountRequest, LockAccountRequest, ResetAccountRequest, UpdateAccountRequest,
};
use crate::modules::admin::service::AdminService;
use async_trait::async_trait;
use chrono::Utc;
use std::sync::Arc;
use uuid::Uuid;

pub struct AdminUserPushDelegate {
    pub admin_service: Arc<AdminService>,
}

impl AdminUserPushDelegate {
    pub fn new(admin_service: Arc<AdminService>) -> Self {
        Self { admin_service }
    }
}

#[async_trait]
impl PushDelegate for AdminUserPushDelegate {
    fn can_handle(&self, entity_type: &str) -> bool {
        entity_type == "admin_user"
    }

    async fn process(
        &self,
        user_id: Uuid,
        _user_role: &str,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let username = match parse_str_field(&op.payload, "username") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let first_name = match parse_str_field(&op.payload, "first_name") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let last_name = match parse_str_field(&op.payload, "last_name") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let role = match parse_str_field(&op.payload, "role") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let client_id = parse_uuid_field(&op.payload, "id").ok();
                let request = CreateAccountRequest {
                    username,
                    first_name,
                    last_name,
                    role,
                    learner_details: None,
                    teacher_details: None,
                };
                match self
                    .admin_service
                    .create_account(request, user_id, client_id)
                    .await
                {
                    Ok(u) => {
                        success_result(op, Some(u.id.to_string()), Some(Utc::now().to_rfc3339()))
                    }
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let target_user_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let action = op
                    .payload
                    .get("action")
                    .and_then(|v| v.as_str())
                    .unwrap_or("update");

                match action {
                    "update" => {
                        let request = UpdateAccountRequest {
                            first_name: op
                                .payload
                                .get("first_name")
                                .and_then(|v| v.as_str())
                                .map(|s| s.to_string()),
                            last_name: op
                                .payload
                                .get("last_name")
                                .and_then(|v| v.as_str())
                                .map(|s| s.to_string()),
                            role: op
                                .payload
                                .get("role")
                                .and_then(|v| v.as_str())
                                .map(|s| s.to_string()),
                        };
                        match self
                            .admin_service
                            .update_account(target_user_id, request, user_id)
                            .await
                        {
                            Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                            Err(e) => error_result(op, &e.to_string()),
                        }
                    }
                    "reset" => {
                        match self
                            .admin_service
                            .reset_account(
                                ResetAccountRequest {
                                    user_id: target_user_id,
                                },
                                user_id,
                            )
                            .await
                        {
                            Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                            Err(e) => error_result(op, &e.to_string()),
                        }
                    }
                    "lock" => {
                        let locked = op
                            .payload
                            .get("locked")
                            .and_then(|v| v.as_bool())
                            .unwrap_or(true);
                        let reason = op
                            .payload
                            .get("reason")
                            .and_then(|v| v.as_str())
                            .map(|s| s.to_string());
                        match self
                            .admin_service
                            .lock_account(
                                LockAccountRequest {
                                    user_id: target_user_id,
                                    locked,
                                    reason,
                                },
                                user_id,
                            )
                            .await
                        {
                            Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                            Err(e) => error_result(op, &e.to_string()),
                        }
                    }
                    _ => error_result(
                        op,
                        &format!("Unknown action for admin_user update: {}", action),
                    ),
                }
            }
            "delete" => {
                let target_user_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                match self
                    .admin_service
                    .delete_account(target_user_id, user_id)
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            _ => error_result(
                op,
                &format!("Unsupported operation for admin_user: {}", op.operation),
            ),
        }
    }
}
