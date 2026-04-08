use uuid::Uuid;
use chrono::Utc;
use super::sync_push_service::{OperationResult, SyncQueueEntry};
use super::extract_field;
use crate::schema::tos_schema::{
    CreateTosRequest, UpdateTosRequest, CreateCompetencyRequest, UpdateCompetencyRequest,
};

impl super::SyncPushService {
    pub(super) async fn handle_tos_operation(
        &self,
        user_id: Uuid,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let client_id = self.parse_uuid_field(&op.payload, "id").ok();
                let class_id = extract_field!(self, op, parse_uuid_field, "class_id");
                let title = extract_field!(self, op, parse_str_field, "title");
                let quarter = extract_field!(self, op, parse_i32_field, "quarter");
                let classification_mode =
                    extract_field!(self, op, parse_str_field, "classification_mode");
                let total_items = extract_field!(self, op, parse_i32_field, "total_items");
                let time_unit = op
                    .payload
                    .get("time_unit")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());
                let easy_percentage = op
                    .payload
                    .get("easy_percentage")
                    .and_then(|v| v.as_f64());
                let medium_percentage = op
                    .payload
                    .get("medium_percentage")
                    .and_then(|v| v.as_f64());
                let hard_percentage = op
                    .payload
                    .get("hard_percentage")
                    .and_then(|v| v.as_f64());
                let remembering_percentage = op
                    .payload
                    .get("remembering_percentage")
                    .and_then(|v| v.as_f64());
                let understanding_percentage = op
                    .payload
                    .get("understanding_percentage")
                    .and_then(|v| v.as_f64());
                let applying_percentage = op
                    .payload
                    .get("applying_percentage")
                    .and_then(|v| v.as_f64());
                let analyzing_percentage = op
                    .payload
                    .get("analyzing_percentage")
                    .and_then(|v| v.as_f64());
                let evaluating_percentage = op
                    .payload
                    .get("evaluating_percentage")
                    .and_then(|v| v.as_f64());
                let creating_percentage = op
                    .payload
                    .get("creating_percentage")
                    .and_then(|v| v.as_f64());

                let request = CreateTosRequest {
                    title,
                    quarter,
                    classification_mode,
                    total_items,
                    time_unit,
                    easy_percentage,
                    medium_percentage,
                    hard_percentage,
                    remembering_percentage,
                    understanding_percentage,
                    applying_percentage,
                    analyzing_percentage,
                    evaluating_percentage,
                    creating_percentage,
                };

                match self
                    .tos_service
                    .create_tos(class_id, user_id, request, client_id)
                    .await
                {
                    Ok(r) => self.success_result(op, Some(r.id.clone()), Some(r.updated_at)),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let tos_id = extract_field!(self, op, parse_uuid_field, "id");
                let title = op
                    .payload
                    .get("title")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());
                let classification_mode = op
                    .payload
                    .get("classification_mode")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());
                let total_items = op
                    .payload
                    .get("total_items")
                    .and_then(|v| v.as_i64())
                    .map(|v| v as i32);
                let time_unit = op
                    .payload
                    .get("time_unit")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());
                let easy_percentage = op
                    .payload
                    .get("easy_percentage")
                    .and_then(|v| v.as_f64());
                let medium_percentage = op
                    .payload
                    .get("medium_percentage")
                    .and_then(|v| v.as_f64());
                let hard_percentage = op
                    .payload
                    .get("hard_percentage")
                    .and_then(|v| v.as_f64());
                let remembering_percentage = op
                    .payload
                    .get("remembering_percentage")
                    .and_then(|v| v.as_f64());
                let understanding_percentage = op
                    .payload
                    .get("understanding_percentage")
                    .and_then(|v| v.as_f64());
                let applying_percentage = op
                    .payload
                    .get("applying_percentage")
                    .and_then(|v| v.as_f64());
                let analyzing_percentage = op
                    .payload
                    .get("analyzing_percentage")
                    .and_then(|v| v.as_f64());
                let evaluating_percentage = op
                    .payload
                    .get("evaluating_percentage")
                    .and_then(|v| v.as_f64());
                let creating_percentage = op
                    .payload
                    .get("creating_percentage")
                    .and_then(|v| v.as_f64());

                let request = UpdateTosRequest {
                    title,
                    classification_mode,
                    total_items,
                    time_unit,
                    easy_percentage,
                    medium_percentage,
                    hard_percentage,
                    remembering_percentage,
                    understanding_percentage,
                    applying_percentage,
                    analyzing_percentage,
                    evaluating_percentage,
                    creating_percentage,
                };

                match self.tos_service.update_tos(tos_id, user_id, request).await {
                    Ok(r) => self.success_result(op, None, Some(r.updated_at)),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "delete" => {
                let tos_id = extract_field!(self, op, parse_uuid_field, "id");
                match self.tos_service.delete_tos(tos_id, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            _ => self.error_result(op, &format!("Unknown operation: {}", op.operation)),
        }
    }

    pub(super) async fn handle_tos_competency_operation(
        &self,
        user_id: Uuid,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let client_id = self.parse_uuid_field(&op.payload, "id").ok();
                let tos_id = extract_field!(self, op, parse_uuid_field, "tos_id");
                let competency_text =
                    extract_field!(self, op, parse_str_field, "competency_text");
                let days_taught = extract_field!(self, op, parse_i32_field, "days_taught");
                let competency_code = op
                    .payload
                    .get("competency_code")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());
                let order_index = op
                    .payload
                    .get("order_index")
                    .and_then(|v| v.as_i64())
                    .map(|v| v as i32);
                let easy_count = op
                    .payload
                    .get("easy_count")
                    .and_then(|v| v.as_i64())
                    .map(|v| v as i32);
                let medium_count = op
                    .payload
                    .get("medium_count")
                    .and_then(|v| v.as_i64())
                    .map(|v| v as i32);
                let hard_count = op
                    .payload
                    .get("hard_count")
                    .and_then(|v| v.as_i64())
                    .map(|v| v as i32);

                let request = CreateCompetencyRequest {
                    competency_code,
                    competency_text,
                    days_taught,
                    order_index,
                    easy_count,
                    medium_count,
                    hard_count,
                };

                // Use client_id as the competency ID if provided
                let result = if let Some(cid) = client_id {
                    self.tos_service
                        .add_competency_with_id(tos_id, user_id, request, cid)
                        .await
                } else {
                    self.tos_service.add_competency(tos_id, user_id, request).await
                };

                match result {
                    Ok(r) => self.success_result(op, Some(r.id.clone()), None),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let competency_id = extract_field!(self, op, parse_uuid_field, "id");
                let competency_text = op
                    .payload
                    .get("competency_text")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());
                let days_taught = op
                    .payload
                    .get("days_taught")
                    .and_then(|v| v.as_i64())
                    .map(|v| v as i32);
                let order_index = op
                    .payload
                    .get("order_index")
                    .and_then(|v| v.as_i64())
                    .map(|v| v as i32);
                let easy_count = op.payload.get("easy_count").map(|v| {
                    if v.is_null() { None } else { v.as_i64().map(|n| n as i32) }
                });
                let medium_count = op.payload.get("medium_count").map(|v| {
                    if v.is_null() { None } else { v.as_i64().map(|n| n as i32) }
                });
                let hard_count = op.payload.get("hard_count").map(|v| {
                    if v.is_null() { None } else { v.as_i64().map(|n| n as i32) }
                });

                let request = UpdateCompetencyRequest {
                    competency_code: None,
                    competency_text,
                    days_taught,
                    order_index,
                    easy_count,
                    medium_count,
                    hard_count,
                };

                match self
                    .tos_service
                    .update_competency(competency_id, user_id, request)
                    .await
                {
                    Ok(_) => self.success_result(op, None, None),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "delete" => {
                let competency_id = extract_field!(self, op, parse_uuid_field, "id");
                match self.tos_service.delete_competency(competency_id, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            _ => self.error_result(op, &format!("Unknown operation: {}", op.operation)),
        }
    }
}
