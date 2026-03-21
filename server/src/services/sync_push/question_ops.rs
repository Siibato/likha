use uuid::Uuid;
use chrono::Utc;
use crate::schema::assessment_schema::{AddQuestionRequest, UpdateQuestionRequest, ChoiceInput, EnumerationItemInput};
use super::sync_push_service::{OperationResult, SyncQueueEntry};
use super::extract_field;

impl super::SyncPushService {
    pub(super) async fn handle_question_operation(&self, user_id: Uuid, op: &SyncQueueEntry) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let assessment_id = extract_field!(self, op, parse_uuid_field, "assessment_id");

                let questions_array = match op.payload.get("questions").and_then(|v| v.as_array()) {
                    Some(arr) => arr,
                    None => return self.error_result(op, "Missing or invalid questions array"),
                };

                let mut questions = Vec::new();
                for q in questions_array {
                    let id = q.get("id")
                        .and_then(|v| v.as_str())
                        .and_then(|s| Uuid::parse_str(s).ok());
                    let question_type = extract_field!(self, op, q, parse_str_field, "question_type");
                    let question_text = extract_field!(self, op, q, parse_str_field, "question_text");
                    let points = extract_field!(self, op, q, parse_i32_field, "points");
                    let order_index = q.get("order_index").and_then(|v| v.as_i64()).unwrap_or(0) as i32;
                    let is_multi_select = q.get("is_multi_select").and_then(|v| v.as_bool());
                    let choices = Self::parse_choices(q);
                    let correct_answers = Self::parse_correct_answers(q);
                    let enumeration_items = Self::parse_enumeration_items(q);

                    questions.push(AddQuestionRequest {
                        id,
                        question_type,
                        question_text,
                        points,
                        order_index,
                        is_multi_select,
                        choices,
                        correct_answers,
                        enumeration_items,
                    });
                }

                match self.assessment_service.insert_questions_for_assessment(assessment_id, questions, user_id).await {
                    Ok(mut responses) => match responses.pop() {
                        Some(r) => self.success_result(op, Some(r.id.to_string()), Some(Utc::now().to_rfc3339())),
                        None => self.error_result(op, "No questions returned from server"),
                    },
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "update" => {
                let question_id = extract_field!(self, op, parse_uuid_field, "id");
                let request = UpdateQuestionRequest {
                    question_text: op.payload.get("question_text").and_then(|v| v.as_str()).map(|s| s.to_string()),
                    points: op.payload.get("points").and_then(|v| v.as_i64()).map(|v| v as i32),
                    order_index: op.payload.get("order_index").and_then(|v| v.as_i64()).map(|v| v as i32),
                    is_multi_select: op.payload.get("is_multi_select").and_then(|v| v.as_bool()),
                    choices: Self::parse_choices(&op.payload),
                    correct_answers: Self::parse_correct_answers(&op.payload),
                    enumeration_items: Self::parse_enumeration_items(&op.payload),
                };
                match self.assessment_service.update_question(question_id, request, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            "delete" => {
                let question_id = extract_field!(self, op, parse_uuid_field, "id");
                match self.assessment_service.delete_question(question_id, user_id).await {
                    Ok(_) => self.success_result(op, None, Some(Utc::now().to_rfc3339())),
                    Err(e) => self.error_result(op, &e.to_string()),
                }
            }
            _ => self.error_result(op, &format!("Unknown operation for question: {}", op.operation)),
        }
    }

    fn parse_choices(payload: &serde_json::Value) -> Option<Vec<ChoiceInput>> {
        payload.get("choices")?.as_array().map(|arr| {
            arr.iter().filter_map(|c| {
                let choice_text = c.get("choice_text").and_then(|v| v.as_str())?.to_string();
                let is_correct = c.get("is_correct").and_then(|v| v.as_bool()).unwrap_or(false);
                let order_index = c.get("order_index").and_then(|v| v.as_i64()).unwrap_or(0) as i32;
                Some(ChoiceInput { choice_text, is_correct, order_index })
            }).collect()
        })
    }

    fn parse_correct_answers(payload: &serde_json::Value) -> Option<Vec<String>> {
        payload.get("correct_answers")?.as_array().map(|arr| {
            arr.iter()
                .filter_map(|a| a.get("answer_text").and_then(|v| v.as_str()).map(|s| s.to_string()))
                .collect()
        })
    }

    fn parse_enumeration_items(payload: &serde_json::Value) -> Option<Vec<EnumerationItemInput>> {
        payload.get("enumeration_items")?.as_array().map(|arr| {
            arr.iter().filter_map(|item| {
                let acceptable_answers = item.get("acceptable_answers")
                    .and_then(|v| v.as_array())
                    .map(|a| a.iter().filter_map(|s| s.as_str().map(|s| s.to_string())).collect())
                    .unwrap_or_default();
                Some(EnumerationItemInput { acceptable_answers })
            }).collect()
        })
    }
}