use super::delegate::PushDelegate;
use super::result_helpers::{
    error_result, parse_i32_field, parse_str_field, parse_uuid_field, success_result,
};
use super::sync_push_service::{OperationResult, SyncQueueEntry};
use crate::modules::grading::schema::{CreateGradeItemRequest, UpdateGradeItemRequest};
use crate::modules::grading::service::GradeComputationService;
use async_trait::async_trait;
use chrono::Utc;
use std::sync::Arc;
use uuid::Uuid;

pub struct GradingPushDelegate {
    pub grade_computation_service: Arc<GradeComputationService>,
}

impl GradingPushDelegate {
    pub fn new(grade_computation_service: Arc<GradeComputationService>) -> Self {
        Self {
            grade_computation_service,
        }
    }

    async fn recompute_after_score_change(&self, grade_item_id: Uuid) {
        if let Ok(Some(item)) = self
            .grade_computation_service
            .repo
            .find_item(grade_item_id)
            .await
        {
            if let Err(e) = self
                .grade_computation_service
                .compute_class_term(item.class_id, item.term_number.unwrap_or(1))
                .await
            {
                tracing::warn!(
                    "Failed to recompute term grades after score change for item {}: {}",
                    grade_item_id,
                    e
                );
            }
        }
    }
}

#[async_trait]
impl PushDelegate for GradingPushDelegate {
    fn can_handle(&self, entity_type: &str) -> bool {
        matches!(entity_type, "grade_config" | "grade_item" | "grade_score")
    }

    async fn process(
        &self,
        _user_id: Uuid,
        _user_role: &str,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.entity_type.as_str() {
            "grade_config" => self.handle_grade_config(op).await,
            "grade_item" => self.handle_grade_item(op).await,
            "grade_score" => self.handle_grade_score(op).await,
            _ => error_result(op, &format!("Unknown entity type: {}", op.entity_type)),
        }
    }
}

impl GradingPushDelegate {
    async fn handle_grade_config(&self, op: &SyncQueueEntry) -> OperationResult {
        match op.operation.as_str() {
            "setup" => {
                let class_id = match parse_uuid_field(&op.payload, "class_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let grade_level = match parse_str_field(&op.payload, "grade_level") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let subject_group = match parse_str_field(&op.payload, "subject_group") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let school_year = match parse_str_field(&op.payload, "school_year") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let semester = op
                    .payload
                    .get("semester")
                    .and_then(|v| v.as_i64())
                    .map(|v| v as i32);

                match self
                    .grade_computation_service
                    .setup_grading(class_id, grade_level, subject_group, school_year, semester)
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let class_id = match parse_uuid_field(&op.payload, "class_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let term_number = match parse_i32_field(&op.payload, "term_number") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let ww_weight = op
                    .payload
                    .get("ww_weight")
                    .and_then(|v| v.as_f64())
                    .unwrap_or(0.0);
                let pt_weight = op
                    .payload
                    .get("pt_weight")
                    .and_then(|v| v.as_f64())
                    .unwrap_or(0.0);
                let qa_weight = op
                    .payload
                    .get("qa_weight")
                    .and_then(|v| v.as_f64())
                    .unwrap_or(0.0);

                match self
                    .grade_computation_service
                    .update_grading_config(class_id, term_number, ww_weight, pt_weight, qa_weight)
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            _ => error_result(
                op,
                &format!("Unknown grade_config operation: {}", op.operation),
            ),
        }
    }

    async fn handle_grade_item(&self, op: &SyncQueueEntry) -> OperationResult {
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
                let component = match parse_str_field(&op.payload, "component") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let term_number = match parse_i32_field(&op.payload, "term_number") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let total_points = op
                    .payload
                    .get("total_points")
                    .and_then(|v| v.as_f64())
                    .unwrap_or(100.0);

                let request = CreateGradeItemRequest {
                    id: op
                        .payload
                        .get("id")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                    title,
                    component,
                    term_number: Some(term_number),
                    total_points,
                    source_type: op
                        .payload
                        .get("source_type")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                    source_id: op
                        .payload
                        .get("source_id")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                };

                match self
                    .grade_computation_service
                    .create_grade_item(class_id, request)
                    .await
                {
                    Ok(r) => success_result(op, Some(r.id), Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let request = UpdateGradeItemRequest {
                    title: op
                        .payload
                        .get("title")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                    component: op
                        .payload
                        .get("component")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                    total_points: op.payload.get("total_points").and_then(|v| v.as_f64()),
                    order_index: op
                        .payload
                        .get("order_index")
                        .and_then(|v| v.as_i64())
                        .map(|v| v as i32),
                    source_type: op
                        .payload
                        .get("source_type")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                    source_id: op
                        .payload
                        .get("source_id")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                };

                match self
                    .grade_computation_service
                    .update_grade_item(id, request)
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "delete" => {
                let id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                match self.grade_computation_service.delete_grade_item(id).await {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            _ => error_result(
                op,
                &format!("Unknown grade_item operation: {}", op.operation),
            ),
        }
    }

    async fn handle_grade_score(&self, op: &SyncQueueEntry) -> OperationResult {
        match op.operation.as_str() {
            "save_scores" => {
                let grade_item_id = match parse_uuid_field(&op.payload, "grade_item_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };

                let scores_array = match op.payload.get("scores").and_then(|v| v.as_array()) {
                    Some(arr) => arr,
                    None => return error_result(op, "Missing or invalid scores array"),
                };

                let mut parsed_scores: Vec<(Uuid, f64)> = Vec::new();
                for entry in scores_array {
                    let student_id = match entry
                        .get("student_id")
                        .and_then(|v| v.as_str())
                        .and_then(|s| Uuid::parse_str(s).ok())
                    {
                        Some(id) => id,
                        None => return error_result(op, "Invalid student_id in scores array"),
                    };
                    let score = match entry.get("score").and_then(|v| v.as_f64()) {
                        Some(s) => s,
                        None => return error_result(op, "Invalid score value in scores array"),
                    };
                    parsed_scores.push((student_id, score));
                }

                match self
                    .grade_computation_service
                    .save_scores(grade_item_id, parsed_scores)
                    .await
                {
                    Ok(_) => {
                        self.recompute_after_score_change(grade_item_id).await;
                        success_result(op, None, Some(Utc::now().to_rfc3339()))
                    }
                    Err(e) => {
                        let error_msg = if e.to_string().contains("does not exist")
                            || e.to_string().contains("FOREIGN KEY constraint failed")
                        {
                            format!("Foreign key constraint failed: {}. This usually happens when the grade item or student no longer exists. The operation will be skipped.", e)
                        } else {
                            e.to_string()
                        };
                        error_result(op, &error_msg)
                    }
                }
            }
            "set_override" => {
                let score_id = match parse_uuid_field(&op.payload, "score_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let override_score = match op.payload.get("override_score").and_then(|v| v.as_f64())
                {
                    Some(s) => s,
                    None => return error_result(op, "Missing or invalid override_score"),
                };

                match self
                    .grade_computation_service
                    .set_override(score_id, override_score)
                    .await
                {
                    Ok(score_resp) => {
                        if let Ok(item_id) = Uuid::parse_str(&score_resp.grade_item_id) {
                            self.recompute_after_score_change(item_id).await;
                        }
                        success_result(op, None, Some(Utc::now().to_rfc3339()))
                    }
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "clear_override" => {
                let score_id = match parse_uuid_field(&op.payload, "score_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };

                match self
                    .grade_computation_service
                    .clear_override(score_id)
                    .await
                {
                    Ok(score_resp) => {
                        if let Ok(item_id) = Uuid::parse_str(&score_resp.grade_item_id) {
                            self.recompute_after_score_change(item_id).await;
                        }
                        success_result(op, None, Some(Utc::now().to_rfc3339()))
                    }
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            _ => error_result(
                op,
                &format!("Unknown grade_score operation: {}", op.operation),
            ),
        }
    }
}
