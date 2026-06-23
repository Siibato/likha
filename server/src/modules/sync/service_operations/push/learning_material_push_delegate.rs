use std::sync::Arc;
use async_trait::async_trait;
use uuid::Uuid;
use chrono::Utc;
use crate::modules::learning_material::service::LearningMaterialService;
use crate::modules::learning_material::schema::{CreateMaterialRequest, UpdateMaterialRequest};
use super::delegate::PushDelegate;
use super::sync_push_service::{OperationResult, SyncQueueEntry};
use super::result_helpers::{error_result, success_result, parse_uuid_field, parse_str_field};

pub struct LearningMaterialPushDelegate {
    pub material_service: Arc<LearningMaterialService>,
}

impl LearningMaterialPushDelegate {
    pub fn new(material_service: Arc<LearningMaterialService>) -> Self {
        Self { material_service }
    }
}

#[async_trait]
impl PushDelegate for LearningMaterialPushDelegate {
    fn can_handle(&self, entity_type: &str) -> bool {
        entity_type == "learning_material"
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
                let client_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(id) => Some(id),
                    Err(e) => return error_result(op, &format!("Client ID is required for material creation: {}", e)),
                };
                let request = CreateMaterialRequest {
                    title,
                    description: op.payload.get("description").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    content_text: op.payload.get("content_text").and_then(|v| v.as_str()).map(|s| s.to_string()),
                };
                match self.material_service.create_material(class_id, request, user_id, client_id).await {
                    Ok(r) => success_result(op, Some(r.id.to_string()), Some(r.updated_at)),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let material_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let request = UpdateMaterialRequest {
                    title: op.payload.get("title").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    description: op.payload.get("description").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    content_text: op.payload.get("content_text").and_then(|v| v.as_str()).map(|s| s.to_string()),
                };
                match self.material_service.update_material(material_id, request, user_id).await {
                    Ok(r) => success_result(op, None, Some(r.updated_at)),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "delete" => {
                let material_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                match self.material_service.soft_delete(material_id, user_id).await {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            _ => error_result(op, &format!("Unknown operation: {}", op.operation)),
        }
    }
}
