use uuid::Uuid;
use chrono::Utc;
use crate::schema::assessment_schema::{SaveAnswersRequest, OverrideAnswerRequest};
use crate::schema::assignment_schema::GradeSubmissionRequest;
use super::sync_push_service::{OperationResult, SyncQueueEntry};

impl super::SyncPushService {
    pub(super) async fn handle_assessment_submission_operation(&self, user_id: Uuid, op: &SyncQueueEntry) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let assessment_id = match self.parse_uuid_field(&op.payload, "assessment_id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                match self.assessment_service.start_assessment(assessment_id, user_id).await {
                    Ok(s) => self.success_result(op, Some(s.submission_id.to_string()), None),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "save_answers" => {
                let submission_id = op.payload.get("submission_id")
                    .or_else(|| op.payload.get("local_id"))
                    .and_then(|v| v.as_str())
                    .and_then(|s| uuid::Uuid::parse_str(s).ok());

                let submission_id = match submission_id {
                    Some(id) => id,
                    None => return self.error_result(op, "Missing or invalid submission_id"),
                };

                let request = match op.payload.get("answers") {
                    Some(answers_val) => match serde_json::from_value::<SaveAnswersRequest>(serde_json::json!({ "answers": answers_val })) {
                        Ok(req) => req,
                        Err(_) => return self.error_result(op, "Invalid answers format"),
                    },
                    None => SaveAnswersRequest { answers: vec![] },
                };

                match self.assessment_service.save_answers(submission_id, request, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "submit" => {
                let submission_id = match self.parse_uuid_field(&op.payload, "submission_id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                match self.assessment_service.submit_assessment(submission_id, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "override_answer" => {
                let answer_id = match self.parse_uuid_field(&op.payload, "answer_id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                let is_correct = op.payload.get("is_correct").and_then(|v| v.as_bool()).unwrap_or(false);
                match self.assessment_service.override_answer(answer_id, OverrideAnswerRequest { is_correct }, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            _ => self.error_result(op, &format!("Unknown operation: {}", op.operation)),
        }
    }

    pub(super) async fn handle_assignment_submission_operation(&self, user_id: Uuid, op: &SyncQueueEntry) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let assignment_id = match self.parse_uuid_field(&op.payload, "assignment_id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                match self.assignment_service.create_or_get_submission(assignment_id, user_id, None).await {
                    Ok(r) => self.success_result(op, Some(r.id.to_string()), Some(r.updated_at)),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "submit" => {
                let submission_id = match self.parse_uuid_field(&op.payload, "submission_id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                match self.assignment_service.submit_assignment(submission_id, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "grade" => {
                let submission_id = match self.parse_uuid_field(&op.payload, "id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                let score = match op.payload.get("score").and_then(|v| v.as_i64()) {
                    Some(s) => s as i32,
                    None => return self.error_result(op, "Missing score field"),
                };
                let request = GradeSubmissionRequest {
                    score,
                    feedback: op.payload.get("feedback").and_then(|v| v.as_str()).map(|s| s.to_string()),
                };
                match self.assignment_service.grade_submission(submission_id, request, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let submission_id = match self.parse_uuid_field(&op.payload, "id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                let action = op.payload.get("action").and_then(|v| v.as_str()).unwrap_or("");
                match action {
                    "return" => match self.assignment_service.return_submission(submission_id, user_id).await {
                        Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                        Err(e) => self.error_result(op, &e.to_string()),
                    },
                    _ => self.error_result(op, &format!("Unknown update action: {}", action)),
                }
            }
            _ => self.error_result(op, &format!("Unknown operation: {}", op.operation)),
        }
    }

    pub(super) async fn handle_submission_file_operation(&self, user_id: Uuid, op: &SyncQueueEntry) -> OperationResult {
        match op.operation.as_str() {
            "delete" => {
                let file_id = match self.parse_uuid_field(&op.payload, "file_id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                match self.assignment_service.delete_file(file_id, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            _ => self.error_result(op, &format!("Unknown operation for submission_file: {}", op.operation)),
        }
    }

    pub(super) async fn handle_material_file_operation(&self, user_id: Uuid, op: &SyncQueueEntry) -> OperationResult {
        match op.operation.as_str() {
            "delete" => {
                let file_id = match self.parse_uuid_field(&op.payload, "file_id") {
                    Ok(id) => id,
                    Err(e) => return self.error_result(op, &e),
                };
                match self.material_service.delete_file(file_id, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            _ => self.error_result(op, &format!("Unknown operation for material_file: {}", op.operation)),
        }
    }

    pub(super) async fn handle_activity_log_operation(&self, _user_id: Uuid, op: &SyncQueueEntry) -> OperationResult {
        self.success_result(op, None, Some(Utc::now().to_rfc3339()))
    }
}