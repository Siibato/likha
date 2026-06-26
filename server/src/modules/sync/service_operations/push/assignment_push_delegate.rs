use super::delegate::PushDelegate;
use super::result_helpers::{error_result, parse_str_field, parse_uuid_field, success_result};
use super::sync_push_service::{OperationResult, SyncQueueEntry};
use crate::modules::assignment::schema::{CreateAssignmentRequest, UpdateAssignmentRequest};
use crate::modules::assignment::service::AssignmentService;
use async_trait::async_trait;
use chrono::Utc;
use std::sync::Arc;
use uuid::Uuid;

pub struct AssignmentPushDelegate {
    pub assignment_service: Arc<AssignmentService>,
}

impl AssignmentPushDelegate {
    pub fn new(assignment_service: Arc<AssignmentService>) -> Self {
        Self { assignment_service }
    }
}

#[async_trait]
impl PushDelegate for AssignmentPushDelegate {
    fn can_handle(&self, entity_type: &str) -> bool {
        entity_type == "assignment"
    }

    async fn process(
        &self,
        user_id: Uuid,
        _user_role: &str,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let class_id = match parse_uuid_field(&op.payload, "class_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let title = match parse_str_field(&op.payload, "title") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let instructions = match parse_str_field(&op.payload, "instructions") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let client_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(id) => Some(id),
                    Err(e) => {
                        return error_result(
                            op,
                            &format!("Client ID is required for assignment creation: {}", e),
                        )
                    }
                };
                let allows_text = op
                    .payload
                    .get("allows_text_submission")
                    .and_then(|v| v.as_bool())
                    .unwrap_or(true);
                let allows_file = op
                    .payload
                    .get("allows_file_submission")
                    .and_then(|v| v.as_bool())
                    .unwrap_or(false);
                let request = CreateAssignmentRequest {
                    id: client_id,
                    title,
                    instructions,
                    total_points: op
                        .payload
                        .get("total_points")
                        .and_then(|v| v.as_i64())
                        .unwrap_or(100) as i32,
                    allows_text_submission: allows_text,
                    allows_file_submission: allows_file,
                    allowed_file_types: None,
                    max_file_size_mb: None,
                    due_at: op
                        .payload
                        .get("due_at")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string())
                        .unwrap_or_else(|| Utc::now().to_rfc3339()),
                    is_published: op.payload.get("is_published").and_then(|v| v.as_bool()),
                    term_number: op
                        .payload
                        .get("term_number")
                        .and_then(|v| v.as_i64())
                        .map(|v| v as i32),
                    component: op
                        .payload
                        .get("component")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                };
                match self
                    .assignment_service
                    .create_assignment(class_id, request, user_id, client_id)
                    .await
                {
                    Ok(r) => success_result(op, Some(r.id.to_string()), Some(r.updated_at)),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let assignment_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let request = UpdateAssignmentRequest {
                    title: op
                        .payload
                        .get("title")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                    instructions: op
                        .payload
                        .get("instructions")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                    total_points: op
                        .payload
                        .get("total_points")
                        .and_then(|v| v.as_i64())
                        .map(|v| v as i32),
                    allows_text_submission: op
                        .payload
                        .get("allows_text_submission")
                        .and_then(|v| v.as_bool()),
                    allows_file_submission: op
                        .payload
                        .get("allows_file_submission")
                        .and_then(|v| v.as_bool()),
                    allowed_file_types: None,
                    max_file_size_mb: None,
                    due_at: op
                        .payload
                        .get("due_at")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                    term_number: op
                        .payload
                        .get("term_number")
                        .and_then(|v| v.as_i64())
                        .map(|v| v as i32),
                    component: op
                        .payload
                        .get("component")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                };
                match self
                    .assignment_service
                    .update_assignment(assignment_id, request, user_id)
                    .await
                {
                    Ok(r) => success_result(op, None, Some(r.updated_at)),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "delete" => {
                let assignment_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                match self
                    .assignment_service
                    .soft_delete(assignment_id, user_id)
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "publish" => {
                let assignment_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                match self
                    .assignment_service
                    .publish_assignment(assignment_id, user_id)
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "unpublish" => {
                let assignment_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                match self
                    .assignment_service
                    .unpublish_assignment(assignment_id, user_id)
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            _ => error_result(op, &format!("Unknown operation: {}", op.operation)),
        }
    }
}
