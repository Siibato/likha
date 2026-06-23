use super::delegate::PushDelegate;
use super::result_helpers::{error_result, parse_str_field, parse_uuid_field, success_result};
use super::sync_push_service::{OperationResult, SyncQueueEntry};
use crate::modules::assessment::schema::{CreateAssessmentRequest, UpdateAssessmentRequest};
use crate::modules::assessment::service::AssessmentService;
use async_trait::async_trait;
use chrono::Utc;
use std::sync::Arc;
use uuid::Uuid;

pub struct AssessmentPushDelegate {
    pub assessment_service: Arc<AssessmentService>,
}

impl AssessmentPushDelegate {
    pub fn new(assessment_service: Arc<AssessmentService>) -> Self {
        Self { assessment_service }
    }
}

#[async_trait]
impl PushDelegate for AssessmentPushDelegate {
    fn can_handle(&self, entity_type: &str) -> bool {
        entity_type == "assessment"
    }

    async fn process(
        &self,
        user_id: Uuid,
        user_role: &str,
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
                let description = op
                    .payload
                    .get("description")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());
                let time_limit = op
                    .payload
                    .get("time_limit_minutes")
                    .and_then(|v| v.as_i64())
                    .unwrap_or(30) as i32;
                let open_at = op
                    .payload
                    .get("open_at")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string())
                    .unwrap_or_else(|| Utc::now().to_rfc3339());
                let close_at = op
                    .payload
                    .get("close_at")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string())
                    .unwrap_or_else(|| {
                        Utc::now()
                            .checked_add_signed(chrono::Duration::hours(1))
                            .unwrap()
                            .to_rfc3339()
                    });

                let client_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(id) => Some(id),
                    Err(e) => {
                        return error_result(
                            op,
                            &format!("Client ID is required for assessment creation: {}", e),
                        )
                    }
                };
                let request = CreateAssessmentRequest {
                    title,
                    description,
                    time_limit_minutes: time_limit,
                    open_at,
                    close_at,
                    show_results_immediately: None,
                    is_published: op.payload.get("is_published").and_then(|v| v.as_bool()),
                    questions: None,
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
                    tos_id: op
                        .payload
                        .get("tos_id")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                };

                match self
                    .assessment_service
                    .create_assessment(class_id, request, user_id, client_id)
                    .await
                {
                    Ok(r) => success_result(op, Some(r.id.to_string()), Some(r.updated_at)),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let assessment_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let request = UpdateAssessmentRequest {
                    title: op
                        .payload
                        .get("title")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                    description: op
                        .payload
                        .get("description")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                    time_limit_minutes: op
                        .payload
                        .get("time_limit_minutes")
                        .and_then(|v| v.as_i64())
                        .map(|v| v as i32),
                    open_at: op
                        .payload
                        .get("open_at")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                    close_at: op
                        .payload
                        .get("close_at")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                    show_results_immediately: None,
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
                    tos_id: op
                        .payload
                        .get("tos_id")
                        .map(|v| v.as_str().map(|s| s.to_string())),
                };
                match self
                    .assessment_service
                    .update_assessment(assessment_id, request, user_id)
                    .await
                {
                    Ok(r) => success_result(op, None, Some(r.updated_at)),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "delete" => {
                let assessment_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                match self
                    .assessment_service
                    .soft_delete(assessment_id, user_id, user_role)
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "publish" => {
                let assessment_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                match self
                    .assessment_service
                    .publish_assessment(assessment_id, user_id)
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "release_results" => {
                let assessment_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                match self
                    .assessment_service
                    .release_results(assessment_id, user_id)
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "unpublish" => {
                let assessment_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                match self
                    .assessment_service
                    .unpublish_assessment(assessment_id, user_id)
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
