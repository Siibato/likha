use super::delegate::PushDelegate;
use super::result_helpers::{error_result, parse_uuid_field, success_result};
use super::sync_push_service::{OperationResult, SyncQueueEntry};
use crate::modules::assessment::schema::{
    GradeEssayRequest, OverrideAnswerRequest, SaveAnswersRequest,
};
use crate::modules::assessment::service::AssessmentService;
use crate::modules::assignment::schema::GradeSubmissionRequest;
use crate::modules::assignment::service::AssignmentService;
use crate::modules::learning_material::service::LearningMaterialService;
use async_trait::async_trait;
use chrono::Utc;
use std::sync::Arc;
use uuid::Uuid;

pub struct SubmissionPushDelegate {
    pub assessment_service: Arc<AssessmentService>,
    pub assignment_service: Arc<AssignmentService>,
    pub material_service: Arc<LearningMaterialService>,
}

impl SubmissionPushDelegate {
    pub fn new(
        assessment_service: Arc<AssessmentService>,
        assignment_service: Arc<AssignmentService>,
        material_service: Arc<LearningMaterialService>,
    ) -> Self {
        Self {
            assessment_service,
            assignment_service,
            material_service,
        }
    }
}

#[async_trait]
impl PushDelegate for SubmissionPushDelegate {
    fn can_handle(&self, entity_type: &str) -> bool {
        matches!(
            entity_type,
            "assessment_submission"
                | "assignment_submission"
                | "submission_file"
                | "material_file"
                | "activity_log"
        )
    }

    async fn process(
        &self,
        user_id: Uuid,
        _user_role: &str,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.entity_type.as_str() {
            "assessment_submission" => self.handle_assessment_submission(user_id, op).await,
            "assignment_submission" => self.handle_assignment_submission(user_id, op).await,
            "submission_file" => self.handle_submission_file(user_id, op).await,
            "material_file" => self.handle_material_file(user_id, op).await,
            "activity_log" => success_result(op, None, Some(Utc::now().to_rfc3339())),
            _ => error_result(op, &format!("Unknown entity type: {}", op.entity_type)),
        }
    }
}

impl SubmissionPushDelegate {
    async fn handle_assessment_submission(
        &self,
        user_id: Uuid,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let assessment_id = match parse_uuid_field(&op.payload, "assessment_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                if let Ok(Some(existing)) = self
                    .assessment_service
                    .assessment_repo
                    .find_by_student_and_assessment(user_id, assessment_id)
                    .await
                {
                    return success_result(op, Some(existing.id.to_string()), None);
                }

                let submission_id = parse_uuid_field(&op.payload, "id").ok();

                match self
                    .assessment_service
                    .start_assessment(assessment_id, user_id, submission_id)
                    .await
                {
                    Ok(s) => success_result(op, Some(s.submission_id.to_string()), None),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "save_answers" => {
                let submission_id = op
                    .payload
                    .get("submission_id")
                    .or_else(|| op.payload.get("local_id"))
                    .and_then(|v| v.as_str())
                    .and_then(|s| uuid::Uuid::parse_str(s).ok());

                let submission_id = match submission_id {
                    Some(id) => id,
                    None => return error_result(op, "Missing or invalid submission_id"),
                };

                let request = match op.payload.get("answers") {
                    Some(answers_val) => match serde_json::from_value::<SaveAnswersRequest>(
                        serde_json::json!({ "answers": answers_val }),
                    ) {
                        Ok(req) => req,
                        Err(_) => return error_result(op, "Invalid answers format"),
                    },
                    None => SaveAnswersRequest { answers: vec![] },
                };

                match self
                    .assessment_service
                    .save_answers(submission_id, request, user_id)
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "submit" => {
                let submission_id = match parse_uuid_field(&op.payload, "submission_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                match self
                    .assessment_service
                    .submit_assessment(submission_id, user_id)
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "override_answer" => {
                let answer_id = match parse_uuid_field(&op.payload, "answer_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let is_correct = op
                    .payload
                    .get("is_correct")
                    .and_then(|v| v.as_bool())
                    .unwrap_or(false);
                let points = op.payload.get("points").and_then(|v| v.as_f64());
                match self
                    .assessment_service
                    .override_answer(
                        answer_id,
                        OverrideAnswerRequest { is_correct, points },
                        user_id,
                    )
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "grade_essay" => {
                let answer_id = match parse_uuid_field(&op.payload, "answer_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let points = op
                    .payload
                    .get("points")
                    .and_then(|v| v.as_f64())
                    .unwrap_or(0.0);
                match self
                    .assessment_service
                    .grade_essay_answer(answer_id, GradeEssayRequest { points }, user_id)
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            _ => error_result(op, &format!("Unknown operation: {}", op.operation)),
        }
    }

    async fn handle_assignment_submission(
        &self,
        user_id: Uuid,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let assignment_id = match parse_uuid_field(&op.payload, "assignment_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let client_submission_id = parse_uuid_field(&op.payload, "id").ok();

                match self
                    .assignment_service
                    .create_or_get_submission(assignment_id, user_id, client_submission_id)
                    .await
                {
                    Ok(r) => success_result(op, Some(r.id.to_string()), Some(r.updated_at)),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "submit" => {
                let submission_id = match parse_uuid_field(&op.payload, "submission_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let text_content = op
                    .payload
                    .get("text_content")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());
                match self
                    .assignment_service
                    .submit_assignment(submission_id, user_id, text_content)
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "grade" => {
                let submission_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let score = match parse_uuid_field(&op.payload, "score") {
                    // Note: the original code used parse_i32_field but had a bug copy
                    Ok(_) => 0i32,
                    Err(_) => {
                        // Actually the original used parse_i32_field("score")
                        let score_val = op
                            .payload
                            .get("score")
                            .and_then(|v| v.as_i64())
                            .unwrap_or(0) as i32;
                        score_val
                    }
                };
                let request = GradeSubmissionRequest {
                    score,
                    feedback: op
                        .payload
                        .get("feedback")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string()),
                };
                match self
                    .assignment_service
                    .grade_submission(submission_id, request, user_id)
                    .await
                {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let submission_id = match parse_uuid_field(&op.payload, "id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                let action = op
                    .payload
                    .get("action")
                    .and_then(|v| v.as_str())
                    .unwrap_or("");
                match action {
                    "return" => match self
                        .assignment_service
                        .return_submission(submission_id, user_id)
                        .await
                    {
                        Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                        Err(e) => error_result(op, &e.to_string()),
                    },
                    _ => error_result(op, &format!("Unknown update action: {}", action)),
                }
            }
            _ => error_result(op, &format!("Unknown operation: {}", op.operation)),
        }
    }

    async fn handle_submission_file(&self, user_id: Uuid, op: &SyncQueueEntry) -> OperationResult {
        match op.operation.as_str() {
            "delete" => {
                let file_id = match parse_uuid_field(&op.payload, "file_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                match self.assignment_service.delete_file(file_id, user_id).await {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            _ => error_result(
                op,
                &format!("Unknown operation for submission_file: {}", op.operation),
            ),
        }
    }

    async fn handle_material_file(&self, user_id: Uuid, op: &SyncQueueEntry) -> OperationResult {
        match op.operation.as_str() {
            "delete" => {
                let file_id = match parse_uuid_field(&op.payload, "file_id") {
                    Ok(v) => v,
                    Err(e) => return error_result(op, &e),
                };
                match self.material_service.delete_file(file_id, user_id).await {
                    Ok(_) => success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => error_result(op, &e.to_string()),
                }
            }
            _ => error_result(
                op,
                &format!("Unknown operation for material_file: {}", op.operation),
            ),
        }
    }
}
