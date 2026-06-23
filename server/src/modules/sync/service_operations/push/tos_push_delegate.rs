use std::sync::Arc;
use async_trait::async_trait;
use uuid::Uuid;
use chrono::Utc;
use crate::modules::tos::service::TosService;
use crate::modules::tos::schema::{
    CreateTosRequest, UpdateTosRequest, CreateCompetencyRequest, UpdateCompetencyRequest,
};
use super::delegate::PushDelegate;
use super::sync_push_service::{OperationResult, SyncQueueEntry};
use super::result_helpers::{error_result, success_result, parse_uuid_field, parse_str_field, parse_i32_field};

pub struct TosPushDelegate {
    pub tos_service: Arc<TosService>,
}

impl TosPushDelegate {
    pub fn new(tos_service: Arc<TosService>) -> Self {
        Self { tos_service }
    }
}

#[async_trait]
impl PushDelegate for TosPushDelegate {
    fn can_handle(&self, entity_type: &str) -> bool {
        matches!(entity_type, "table_of_specifications" | "tos_competency")
    }

    async fn process(
        &self,
        user_id: Uuid,
        _user_role: &str,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.entity_type.as_str() {
            "table_of_specifications" => self.handle_tos(user_id, op).await,
            "tos_competency" => self.handle_tos_competency(user_id, op).await,
            _ => error_result(op, &format!("Unknown entity type: {}", op.entity_type)),
        }
    }
}

impl TosPushDelegate {
    async fn handle_tos(&self, user_id: Uuid, op: &SyncQueueEntry) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let client_id = parse_uuid_field(&op.payload, "id").ok();
                let class_id = match parse_uuid_field(&op.payload, "class_id") { Ok(v) => v, Err(e) => return error_result(op, &e) };
                let title = match parse_str_field(&op.payload, "title") { Ok(v) => v, Err(e) => return error_result(op, &e) };
                let term_number = match parse_i32_field(&op.payload, "term_number") { Ok(v) => v, Err(e) => return error_result(op, &e) };
                let classification_mode = match parse_str_field(&op.payload, "classification_mode") { Ok(v) => v, Err(e) => return error_result(op, &e) };
                let total_items = match parse_i32_field(&op.payload, "total_items") { Ok(v) => v, Err(e) => return error_result(op, &e) };
                let time_unit = op.payload.get("time_unit").and_then(|v| v.as_str()).map(|s| s.to_string());
                let easy_percentage = op.payload.get("easy_percentage").and_then(|v| v.as_f64());
                let medium_percentage = op.payload.get("medium_percentage").and_then(|v| v.as_f64());
                let hard_percentage = op.payload.get("hard_percentage").and_then(|v| v.as_f64());
                let remembering_percentage = op.payload.get("remembering_percentage").and_then(|v| v.as_f64());
                let understanding_percentage = op.payload.get("understanding_percentage").and_then(|v| v.as_f64());
                let applying_percentage = op.payload.get("applying_percentage").and_then(|v| v.as_f64());
                let analyzing_percentage = op.payload.get("analyzing_percentage").and_then(|v| v.as_f64());
                let evaluating_percentage = op.payload.get("evaluating_percentage").and_then(|v| v.as_f64());
                let creating_percentage = op.payload.get("creating_percentage").and_then(|v| v.as_f64());

                let request = CreateTosRequest {
                    id: client_id.map(|u| u.to_string()), title, term_number, classification_mode,
                    total_items, time_unit, easy_percentage, medium_percentage, hard_percentage,
                    remembering_percentage, understanding_percentage, applying_percentage,
                    analyzing_percentage, evaluating_percentage, creating_percentage,
                };

                match self.tos_service.create_tos(class_id, user_id, request, client_id).await {
                    Ok(r) => success_result(op, Some(r.id.clone()), Some(r.updated_at)),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let tos_id = match parse_uuid_field(&op.payload, "id") { Ok(v) => v, Err(e) => return error_result(op, &e) };
                let request = UpdateTosRequest {
                    title: op.payload.get("title").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    classification_mode: op.payload.get("classification_mode").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    total_items: op.payload.get("total_items").and_then(|v| v.as_i64()).map(|v| v as i32),
                    time_unit: op.payload.get("time_unit").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    easy_percentage: op.payload.get("easy_percentage").and_then(|v| v.as_f64()),
                    medium_percentage: op.payload.get("medium_percentage").and_then(|v| v.as_f64()),
                    hard_percentage: op.payload.get("hard_percentage").and_then(|v| v.as_f64()),
                    remembering_percentage: op.payload.get("remembering_percentage").and_then(|v| v.as_f64()),
                    understanding_percentage: op.payload.get("understanding_percentage").and_then(|v| v.as_f64()),
                    applying_percentage: op.payload.get("applying_percentage").and_then(|v| v.as_f64()),
                    analyzing_percentage: op.payload.get("analyzing_percentage").and_then(|v| v.as_f64()),
                    evaluating_percentage: op.payload.get("evaluating_percentage").and_then(|v| v.as_f64()),
                    creating_percentage: op.payload.get("creating_percentage").and_then(|v| v.as_f64()),
                };
                match self.tos_service.update_tos(tos_id, user_id, request).await {
                    Ok(r) => success_result(op, None, Some(r.updated_at)),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "delete" => {
                let tos_id = match parse_uuid_field(&op.payload, "id") { Ok(v) => v, Err(e) => return error_result(op, &e) };
                match self.tos_service.delete_tos(tos_id, user_id).await {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            _ => error_result(op, &format!("Unknown operation: {}", op.operation)),
        }
    }

    async fn handle_tos_competency(&self, user_id: Uuid, op: &SyncQueueEntry) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let client_id = parse_uuid_field(&op.payload, "id").ok();
                let tos_id = match parse_uuid_field(&op.payload, "tos_id") { Ok(v) => v, Err(e) => return error_result(op, &e) };
                let competency_text = match parse_str_field(&op.payload, "competency_text") { Ok(v) => v, Err(e) => return error_result(op, &e) };
                let time_units_taught = match parse_i32_field(&op.payload, "time_units_taught") { Ok(v) => v, Err(e) => return error_result(op, &e) };
                let competency_code = op.payload.get("competency_code").and_then(|v| v.as_str()).map(|s| s.to_string());
                let order_index = op.payload.get("order_index").and_then(|v| v.as_i64()).map(|v| v as i32);
                let easy_count = op.payload.get("easy_count").and_then(|v| v.as_i64()).map(|v| v as i32);
                let medium_count = op.payload.get("medium_count").and_then(|v| v.as_i64()).map(|v| v as i32);
                let hard_count = op.payload.get("hard_count").and_then(|v| v.as_i64()).map(|v| v as i32);

                let request = CreateCompetencyRequest {
                    id: client_id.map(|u| u.to_string()), competency_code, competency_text,
                    time_units_taught, order_index, easy_count, medium_count, hard_count,
                    remembering_count: op.payload.get("remembering_count").and_then(|v| v.as_i64()).map(|v| v as i32),
                    understanding_count: op.payload.get("understanding_count").and_then(|v| v.as_i64()).map(|v| v as i32),
                    applying_count: op.payload.get("applying_count").and_then(|v| v.as_i64()).map(|v| v as i32),
                    analyzing_count: op.payload.get("analyzing_count").and_then(|v| v.as_i64()).map(|v| v as i32),
                    evaluating_count: op.payload.get("evaluating_count").and_then(|v| v.as_i64()).map(|v| v as i32),
                    creating_count: op.payload.get("creating_count").and_then(|v| v.as_i64()).map(|v| v as i32),
                };

                let result = if let Some(cid) = client_id {
                    self.tos_service.add_competency_with_id(tos_id, user_id, request, cid).await
                } else {
                    self.tos_service.add_competency(tos_id, user_id, request).await
                };

                match result {
                    Ok(r) => success_result(op, Some(r.id.clone()), None),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let competency_id = match parse_uuid_field(&op.payload, "id") { Ok(v) => v, Err(e) => return error_result(op, &e) };
                let competency_text = op.payload.get("competency_text").and_then(|v| v.as_str()).map(|s| s.to_string());
                let time_units_taught = op.payload.get("time_units_taught").and_then(|v| v.as_i64()).map(|v| v as i32);
                let order_index = op.payload.get("order_index").and_then(|v| v.as_i64()).map(|v| v as i32);
                let easy_count = op.payload.get("easy_count").map(|v| if v.is_null() { None } else { v.as_i64().map(|n| n as i32) });
                let medium_count = op.payload.get("medium_count").map(|v| if v.is_null() { None } else { v.as_i64().map(|n| n as i32) });
                let hard_count = op.payload.get("hard_count").map(|v| if v.is_null() { None } else { v.as_i64().map(|n| n as i32) });

                let request = UpdateCompetencyRequest {
                    competency_code: None, competency_text, time_units_taught, order_index,
                    easy_count, medium_count, hard_count,
                    remembering_count: op.payload.get("remembering_count").map(|v| if v.is_null() { None } else { v.as_i64().map(|n| n as i32) }),
                    understanding_count: op.payload.get("understanding_count").map(|v| if v.is_null() { None } else { v.as_i64().map(|n| n as i32) }),
                    applying_count: op.payload.get("applying_count").map(|v| if v.is_null() { None } else { v.as_i64().map(|n| n as i32) }),
                    analyzing_count: op.payload.get("analyzing_count").map(|v| if v.is_null() { None } else { v.as_i64().map(|n| n as i32) }),
                    evaluating_count: op.payload.get("evaluating_count").map(|v| if v.is_null() { None } else { v.as_i64().map(|n| n as i32) }),
                    creating_count: op.payload.get("creating_count").map(|v| if v.is_null() { None } else { v.as_i64().map(|n| n as i32) }),
                };

                match self.tos_service.update_competency(competency_id, user_id, request).await {
                    Ok(_) => success_result(op, None, None),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "delete" => {
                let competency_id = match parse_uuid_field(&op.payload, "id") { Ok(v) => v, Err(e) => return error_result(op, &e) };
                match self.tos_service.delete_competency(competency_id, user_id).await {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            _ => error_result(op, &format!("Unknown operation: {}", op.operation)),
        }
    }
}
