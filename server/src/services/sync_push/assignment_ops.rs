use uuid::Uuid;
use chrono::Utc;
use crate::schema::assignment_schema::{CreateAssignmentRequest, UpdateAssignmentRequest};
use super::sync_push_service::{OperationResult, SyncQueueEntry};

impl super::SyncPushService {
    pub(super) async fn handle_assignment_operation(&self, user_id: Uuid, _user_role: &str, op: &SyncQueueEntry) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let class_id = match self.parse_uuid_field(&op.payload, "class_id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                let title = match self.parse_str_field(&op.payload, "title") {
                    Ok(v) => v,
                    Err(e) => return self.error_result(op, &e),
                };
                let instructions = match self.parse_str_field(&op.payload, "instructions") {
                    Ok(v) => v,
                    Err(e) => return self.error_result(op, &e),
                };
                let client_id = match self.parse_uuid_field(&op.payload, "id") {
                    Ok(id) => Some(id),
                    Err(e) => return self.error_result(op, &format!("Client ID is required for assignment creation: {}", e)),
                };
                let request = CreateAssignmentRequest {
                    title,
                    instructions,
                    total_points: op.payload.get("total_points").and_then(|v| v.as_i64()).unwrap_or(100) as i32,
                    submission_type: op.payload.get("submission_type").and_then(|v| v.as_str()).unwrap_or("text").to_string(),
                    allowed_file_types: None,
                    max_file_size_mb: None,
                    due_at: op.payload.get("due_at").and_then(|v| v.as_str()).map(|s| s.to_string())
                        .unwrap_or_else(|| Utc::now().to_rfc3339()),
                    is_published: op.payload.get("is_published").and_then(|v| v.as_bool()),
                };
                match self.assignment_service.create_assignment(class_id, request, user_id, client_id).await {
                    Ok(r) => self.success_result(op, Some(r.id.to_string()), Some(r.updated_at)),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let assignment_id = match self.parse_uuid_field(&op.payload, "id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                let request = UpdateAssignmentRequest {
                    title: op.payload.get("title").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    instructions: op.payload.get("instructions").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    total_points: op.payload.get("total_points").and_then(|v| v.as_i64()).map(|v| v as i32),
                    submission_type: op.payload.get("submission_type").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    allowed_file_types: None,
                    max_file_size_mb: None,
                    due_at: op.payload.get("due_at").and_then(|v| v.as_str()).map(|s| s.to_string()),
                };
                match self.assignment_service.update_assignment(assignment_id, request, user_id).await {
                    Ok(r) => self.success_result(op, None, Some(r.updated_at)),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "delete" => {
                let assignment_id = match self.parse_uuid_field(&op.payload, "id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                match self.assignment_service.soft_delete(assignment_id, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "publish" => {
                let assignment_id = match self.parse_uuid_field(&op.payload, "id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                match self.assignment_service.publish_assignment(assignment_id, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "unpublish" => {
                let assignment_id = match self.parse_uuid_field(&op.payload, "id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                match self.assignment_service.unpublish_assignment(assignment_id, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            _ => self.error_result(op, &format!("Unknown operation: {}", op.operation)),
        }
    }
}