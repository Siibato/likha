use uuid::Uuid;
use chrono::Utc;
use crate::schema::learning_material_schema::{CreateMaterialRequest, UpdateMaterialRequest};
use super::sync_push_service::{OperationResult, SyncQueueEntry};

impl super::SyncPushService {
    pub(super) async fn handle_learning_material_operation(&self, user_id: Uuid, op: &SyncQueueEntry) -> OperationResult {
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
                let client_id = self.parse_uuid_field(&op.payload, "id").ok();
                let request = CreateMaterialRequest {
                    title,
                    description: op.payload.get("description").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    content_text: op.payload.get("content_text").and_then(|v| v.as_str()).map(|s| s.to_string()),
                };
                match self.material_service.create_material(class_id, request, user_id, client_id).await {
                    Ok(r) => self.success_result(op, Some(r.id.to_string()), Some(r.updated_at)),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let material_id = match self.parse_uuid_field(&op.payload, "id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                let request = UpdateMaterialRequest {
                    title: op.payload.get("title").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    description: op.payload.get("description").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    content_text: op.payload.get("content_text").and_then(|v| v.as_str()).map(|s| s.to_string()),
                };
                match self.material_service.update_material(material_id, request, user_id).await {
                    Ok(r) => self.success_result(op, None, Some(r.updated_at)),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "delete" => {
                let material_id = match self.parse_uuid_field(&op.payload, "id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                match self.material_service.soft_delete(material_id, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            _ => self.error_result(op, &format!("Unknown operation: {}", op.operation)),
        }
    }
}