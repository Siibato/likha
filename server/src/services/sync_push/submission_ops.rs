use uuid::Uuid;
use chrono::Utc;
use crate::schema::assessment_schema::{SaveAnswersRequest, OverrideAnswerRequest};
use crate::schema::assignment_schema::GradeSubmissionRequest;
use super::sync_push_service::{OperationResult, SyncQueueEntry};
use super::extract_field;

impl super::SyncPushService {
    pub(super) async fn handle_assessment_submission_operation(&self, user_id: Uuid, op: &SyncQueueEntry) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let assessment_id = extract_field!(self, op, parse_uuid_field, "assessment_id");
                // Idempotency: return existing server_id so downstream saveAnswers/submit can proceed
                if let Ok(Some(existing)) = self.assessment_service.submission_repo
                    .find_by_student_and_assessment(user_id, assessment_id).await
                {
                    return self.success_result(op, Some(existing.id.to_string()), None);
                }

                // Extract optional submission_id from payload (client-provided UUID)
                let submission_id = self.parse_uuid_field(&op.payload, "id").ok();

                match self.assessment_service.start_assessment(assessment_id, user_id, submission_id).await {
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
                let submission_id = extract_field!(self, op, parse_uuid_field, "submission_id");
                match self.assessment_service.submit_assessment(submission_id, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "override_answer" => {
                let answer_id = extract_field!(self, op, parse_uuid_field, "answer_id");
                let is_correct = op.payload.get("is_correct").and_then(|v| v.as_bool()).unwrap_or(false);
                let points = op.payload.get("points").and_then(|v| v.as_f64());
                match self.assessment_service.override_answer(answer_id, OverrideAnswerRequest { is_correct, points }, user_id).await {
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
                let assignment_id = extract_field!(self, op, parse_uuid_field, "assignment_id");
                // Extract optional submission_id from payload (client-provided UUID)
                let submission_id = self.parse_uuid_field(&op.payload, "id").ok();

                match self.assignment_service.create_or_get_submission(assignment_id, user_id, None, submission_id).await {
                    Ok(r) => self.success_result(op, Some(r.id.to_string()), Some(r.updated_at)),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "submit" => {
                let submission_id = extract_field!(self, op, parse_uuid_field, "submission_id");
                let text_content = op.payload.get("text_content").and_then(|v| v.as_str()).map(|s| s.to_string());
                match self.assignment_service.submit_assignment(submission_id, user_id, text_content).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "grade" => {
                let submission_id = extract_field!(self, op, parse_uuid_field, "id");
                let score = extract_field!(self, op, parse_i32_field, "score");
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
                let submission_id = extract_field!(self, op, parse_uuid_field, "id");
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
                let file_id = extract_field!(self, op, parse_uuid_field, "file_id");
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
                let file_id = extract_field!(self, op, parse_uuid_field, "file_id");
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