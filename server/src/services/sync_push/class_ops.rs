use uuid::Uuid;
use chrono::Utc;
use super::sync_push_service::{OperationResult, SyncQueueEntry};
use crate::schema::class_schema::{CreateClassRequest, UpdateClassRequest};

impl super::SyncPushService {
    pub(super) async fn handle_class_operation(&self, user_id: Uuid, user_role: &str, op: &SyncQueueEntry) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let title = match self.parse_str_field(&op.payload, "title") {
                    Ok(v) => v,
                    Err(e) => return self.error_result(op, &e),
                };
                let description = op.payload.get("description").and_then(|v| v.as_str()).map(|s| s.to_string());
                let teacher_id = op.payload
                    .get("teacher_id")
                    .and_then(|v| v.as_str())
                    .and_then(|s| Uuid::parse_str(s).ok());
                let request = CreateClassRequest { title, description, teacher_id };

                match self.class_service.create_class(request, user_id).await {
                    Ok(r) => self.success_result(op, Some(r.id.to_string()), Some(r.updated_at)),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let class_id = match self.parse_uuid_field(&op.payload, "id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                let title = op.payload.get("title").and_then(|v| v.as_str()).map(|s| s.to_string());
                let description = op.payload.get("description").and_then(|v| v.as_str()).map(|s| s.to_string());
                let request = UpdateClassRequest { title, description };

                match self.class_service.update_class(class_id, request, user_id).await {
                    Ok(r) => self.success_result(op, None, Some(r.updated_at)),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "delete" => {
                let class_id = match self.parse_uuid_field(&op.payload, "id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                match self.class_service.soft_delete(class_id, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "add_enrollment" => {
                let class_id = match self.parse_uuid_field(&op.payload, "class_id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                let student_id = match self.parse_uuid_field(&op.payload, "student_id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };

                let is_enrolled = match self.class_service
                    .is_student_enrolled(class_id, student_id)
                    .await
                {
                    Ok(enrolled) => enrolled,
                    Err(e) => return self.error_result(op, &e.to_string()),
                };

                if is_enrolled {
                    return self.success_result(op, None, Some(Utc::now().to_rfc3339()));
                }

                match self.class_service.add_student(class_id, student_id, user_id, &user_role).await {
                    Ok(r) => self.success_result(op, Some(r.id.to_string()), Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "remove_enrollment" => {
                let class_id = match self.parse_uuid_field(&op.payload, "class_id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                let student_id = match self.parse_uuid_field(&op.payload, "student_id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                match self.class_service.remove_student(class_id, student_id, user_id, &user_role).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            _ => self.error_result(op, &format!("Unknown operation: {}", op.operation)),
        }
    }
}