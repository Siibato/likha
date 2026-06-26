use super::delegate::PushDelegate;
use super::result_helpers::{error_result, parse_str_field, parse_uuid_field, success_result};
use super::sync_push_service::{OperationResult, SyncQueueEntry};
use crate::modules::class::schema::{CreateClassRequest, UpdateClassRequest};
use crate::modules::class::service::ClassService;
use async_trait::async_trait;
use chrono::Utc;
use std::sync::Arc;
use uuid::Uuid;

pub struct ClassPushDelegate {
    pub class_service: Arc<ClassService>,
}

impl ClassPushDelegate {
    pub fn new(class_service: Arc<ClassService>) -> Self {
        Self { class_service }
    }
}

#[async_trait]
impl PushDelegate for ClassPushDelegate {
    fn can_handle(&self, entity_type: &str) -> bool {
        entity_type == "class"
    }

    async fn process(
        &self,
        user_id: Uuid,
        user_role: &str,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let title = match parse_str_field(&op.payload, "title") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let description = op
                    .payload
                    .get("description")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());
                let teacher_id = op
                    .payload
                    .get("teacher_id")
                    .and_then(|v| v.as_str())
                    .and_then(|s| Uuid::parse_str(s).ok());
                let client_id = parse_uuid_field(&op.payload, "id").ok();
                let is_advisory = op.payload.get("is_advisory").and_then(|v| v.as_bool());
                let request = CreateClassRequest {
                    id: client_id,
                    title,
                    description,
                    teacher_id,
                    is_advisory,
                };

                match self
                    .class_service
                    .create_class(request, user_id, client_id)
                    .await
                {
                    Ok(r) => success_result(op, Some(r.id.to_string()), Some(r.updated_at)),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let class_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let title = op
                    .payload
                    .get("title")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());
                let description = op
                    .payload
                    .get("description")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());
                let teacher_id = op
                    .payload
                    .get("teacher_id")
                    .and_then(|v| v.as_str())
                    .and_then(|s| Uuid::parse_str(s).ok());
                let is_advisory = op.payload.get("is_advisory").and_then(|v| v.as_bool());
                let request = UpdateClassRequest {
                    title,
                    description,
                    teacher_id,
                    is_advisory,
                };

                match self
                    .class_service
                    .update_class(class_id, request, user_id, user_role)
                    .await
                {
                    Ok(r) => success_result(op, None, Some(r.updated_at)),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "delete" => {
                let class_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                match self
                    .class_service
                    .soft_delete(class_id, user_id, user_role)
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "add_enrollment" => {
                let class_id = match parse_uuid_field(&op.payload, "class_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let student_id = match parse_uuid_field(&op.payload, "student_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };

                let is_enrolled = match self
                    .class_service
                    .is_student_enrolled(class_id, student_id)
                    .await
                {
                    Ok(enrolled) => enrolled,
                    Err(e) => return error_result(op, &e.to_string()),
                };

                if is_enrolled {
                    return success_result(op, None, Some(Utc::now().to_rfc3339()));
                }

                match self
                    .class_service
                    .add_student(class_id, student_id, user_id, &user_role)
                    .await
                {
                    Ok(r) => {
                        success_result(op, Some(r.id.to_string()), Some(Utc::now().to_rfc3339()))
                    }
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "remove_enrollment" => {
                let class_id = match parse_uuid_field(&op.payload, "class_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let student_id = match parse_uuid_field(&op.payload, "student_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                match self
                    .class_service
                    .remove_student(class_id, student_id, user_id, &user_role)
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
