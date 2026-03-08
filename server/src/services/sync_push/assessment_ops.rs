use uuid::Uuid;
use chrono::Utc;
use crate::schema::assessment_schema::{CreateAssessmentRequest, UpdateAssessmentRequest};
use super::sync_push_service::{OperationResult, SyncQueueEntry};

impl super::SyncPushService {
    pub(super) async fn handle_assessment_operation(&self, user_id: Uuid, user_role: &str, op: &SyncQueueEntry) -> OperationResult {
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
                let description = op.payload.get("description").and_then(|v| v.as_str()).map(|s| s.to_string());
                let time_limit = op.payload.get("time_limit_minutes").and_then(|v| v.as_i64()).unwrap_or(30) as i32;
                let open_at = op.payload.get("open_at").and_then(|v| v.as_str()).map(|s| s.to_string())
                    .unwrap_or_else(|| Utc::now().to_rfc3339());
                let close_at = op.payload.get("close_at").and_then(|v| v.as_str()).map(|s| s.to_string())
                    .unwrap_or_else(|| Utc::now().checked_add_signed(chrono::Duration::hours(1)).unwrap().to_rfc3339());

                let client_id = self.parse_uuid_field(&op.payload, "id").ok();
                let request = CreateAssessmentRequest {
                    title,
                    description,
                    time_limit_minutes: time_limit,
                    open_at,
                    close_at,
                    show_results_immediately: None,
                    is_published: op.payload.get("is_published").and_then(|v| v.as_bool()),
                };

                match self.assessment_service.create_assessment(class_id, request, user_id, client_id).await {
                    Ok(r) => self.success_result(op, Some(r.id.to_string()), Some(r.updated_at)),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let assessment_id = match self.parse_uuid_field(&op.payload, "id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                let request = UpdateAssessmentRequest {
                    title: op.payload.get("title").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    description: op.payload.get("description").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    time_limit_minutes: op.payload.get("time_limit_minutes").and_then(|v| v.as_i64()).map(|v| v as i32),
                    open_at: op.payload.get("open_at").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    close_at: op.payload.get("close_at").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    show_results_immediately: None,
                };
                match self.assessment_service.update_assessment(assessment_id, request, user_id).await {
                    Ok(r) => self.success_result(op, None, Some(r.updated_at)),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "delete" => {
                let assessment_id = match self.parse_uuid_field(&op.payload, "id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                match self.assessment_service.soft_delete(assessment_id, user_id, user_role).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "publish" => {
                let assessment_id = match self.parse_uuid_field(&op.payload, "id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                match self.assessment_service.publish_assessment(assessment_id, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "release_results" => {
                let assessment_id = match self.parse_uuid_field(&op.payload, "id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                match self.assessment_service.release_results(assessment_id, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            _ => self.error_result(op, &format!("Unknown operation: {}", op.operation)),
        }
    }
}