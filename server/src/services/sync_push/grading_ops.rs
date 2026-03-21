use uuid::Uuid;
use chrono::Utc;
use crate::schema::grading_schema::{CreateGradeItemRequest, UpdateGradeItemRequest};
use super::sync_push_service::{OperationResult, SyncQueueEntry};
use super::extract_field;

impl super::SyncPushService {
    pub(super) async fn handle_grade_config_operation(
        &self,
        _user_id: Uuid,
        _user_role: &str,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "setup" => {
                let class_id = extract_field!(self, op, parse_uuid_field, "class_id");
                let grade_level = extract_field!(self, op, parse_str_field, "grade_level");
                let subject_group = extract_field!(self, op, parse_str_field, "subject_group");
                let school_year = extract_field!(self, op, parse_str_field, "school_year");
                let semester = op.payload.get("semester").and_then(|v| v.as_i64()).map(|v| v as i32);

                match self.grade_computation_service.setup_grading(
                    class_id, grade_level, subject_group, school_year, semester,
                ).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let class_id = extract_field!(self, op, parse_uuid_field, "class_id");
                let quarter = extract_field!(self, op, parse_i32_field, "quarter");
                let ww_weight = op.payload.get("ww_weight")
                    .and_then(|v| v.as_f64())
                    .unwrap_or(0.0);
                let pt_weight = op.payload.get("pt_weight")
                    .and_then(|v| v.as_f64())
                    .unwrap_or(0.0);
                let qa_weight = op.payload.get("qa_weight")
                    .and_then(|v| v.as_f64())
                    .unwrap_or(0.0);

                match self.grade_computation_service.update_grading_config(
                    class_id, quarter, ww_weight, pt_weight, qa_weight,
                ).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            _ => self.error_result(op, &format!("Unknown grade_config operation: {}", op.operation)),
        }
    }

    pub(super) async fn handle_grade_item_operation(
        &self,
        _user_id: Uuid,
        _user_role: &str,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let class_id = extract_field!(self, op, parse_uuid_field, "class_id");
                let title = extract_field!(self, op, parse_str_field, "title");
                let component = extract_field!(self, op, parse_str_field, "component");
                let quarter = extract_field!(self, op, parse_i32_field, "quarter");
                let total_points = op.payload.get("total_points")
                    .and_then(|v| v.as_f64())
                    .unwrap_or(100.0);
                let is_departmental_exam = op.payload.get("is_departmental_exam")
                    .and_then(|v| v.as_bool());

                let request = CreateGradeItemRequest {
                    title,
                    component,
                    quarter,
                    total_points,
                    is_departmental_exam,
                };

                match self.grade_computation_service.create_grade_item(class_id, request).await {
                    Ok(r) => self.success_result(op, Some(r.id), Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let id = extract_field!(self, op, parse_uuid_field, "id");
                let request = UpdateGradeItemRequest {
                    title: op.payload.get("title").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    component: op.payload.get("component").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    total_points: op.payload.get("total_points").and_then(|v| v.as_f64()),
                    order_index: op.payload.get("order_index").and_then(|v| v.as_i64()).map(|v| v as i32),
                };

                match self.grade_computation_service.update_grade_item(id, request).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "delete" => {
                let id = extract_field!(self, op, parse_uuid_field, "id");
                match self.grade_computation_service.delete_grade_item(id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            _ => self.error_result(op, &format!("Unknown grade_item operation: {}", op.operation)),
        }
    }

    pub(super) async fn handle_grade_score_operation(
        &self,
        _user_id: Uuid,
        _user_role: &str,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "save_scores" => {
                let grade_item_id = extract_field!(self, op, parse_uuid_field, "grade_item_id");

                let scores_array = match op.payload.get("scores").and_then(|v| v.as_array()) {
                    Some(arr) => arr,
                    None => return self.error_result(op, "Missing or invalid scores array"),
                };

                let mut parsed_scores: Vec<(Uuid, f64)> = Vec::new();
                for entry in scores_array {
                    let student_id = match entry.get("student_id")
                        .and_then(|v| v.as_str())
                        .and_then(|s| Uuid::parse_str(s).ok())
                    {
                        Some(id) => id,
                        None => return self.error_result(op, "Invalid student_id in scores array"),
                    };
                    let score = match entry.get("score").and_then(|v| v.as_f64()) {
                        Some(s) => s,
                        None => return self.error_result(op, "Invalid score value in scores array"),
                    };
                    parsed_scores.push((student_id, score));
                }

                match self.grade_computation_service.save_scores(grade_item_id, parsed_scores).await {
                    Ok(_) => {
                        // Trigger recomputation for affected class+quarter
                        self.recompute_after_score_change(grade_item_id).await;
                        self.success_result(op, None, Some(Utc::now().to_rfc3339()))
                    }
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "set_override" => {
                let score_id = extract_field!(self, op, parse_uuid_field, "score_id");
                let override_score = match op.payload.get("override_score").and_then(|v| v.as_f64()) {
                    Some(s) => s,
                    None => return self.error_result(op, "Missing or invalid override_score"),
                };

                match self.grade_computation_service.set_override(score_id, override_score).await {
                    Ok(score_resp) => {
                        // Trigger recomputation — need grade_item_id from the score response
                        if let Ok(item_id) = Uuid::parse_str(&score_resp.grade_item_id) {
                            self.recompute_after_score_change(item_id).await;
                        }
                        self.success_result(op, None, Some(Utc::now().to_rfc3339()))
                    }
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "clear_override" => {
                let score_id = extract_field!(self, op, parse_uuid_field, "score_id");

                match self.grade_computation_service.clear_override(score_id).await {
                    Ok(score_resp) => {
                        if let Ok(item_id) = Uuid::parse_str(&score_resp.grade_item_id) {
                            self.recompute_after_score_change(item_id).await;
                        }
                        self.success_result(op, None, Some(Utc::now().to_rfc3339()))
                    }
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            _ => self.error_result(op, &format!("Unknown grade_score operation: {}", op.operation)),
        }
    }

    /// After any score change, recompute quarterly grades for the affected class+quarter.
    async fn recompute_after_score_change(&self, grade_item_id: Uuid) {
        if let Ok(Some(item)) = self.grade_computation_service.repo.find_item(grade_item_id).await {
            if let Err(e) = self.grade_computation_service
                .compute_class_quarterly(item.class_id, item.quarter)
                .await
            {
                tracing::warn!(
                    "Failed to recompute quarterly grades after score change for item {}: {}",
                    grade_item_id, e
                );
            }
        }
    }
}
