use sea_orm::*;
use serde_json::{json, Value};
use std::collections::HashMap;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::{
    answer_key_acceptable_answers, answer_keys, question_choices,
};

/// Enriches questions with role-aware nested data (choices, correct answers, enumeration items).
///
/// - Students: receive choices WITHOUT `is_correct`, no correct_answers, enumeration_count only
/// - Teachers/Admins: receive full data including `is_correct`, acceptable_answers, full enumeration items
pub async fn enrich_questions(
    db: &DatabaseConnection,
    questions: Vec<Value>,
    user_role: &str,
) -> AppResult<Vec<Value>> {
    if questions.is_empty() {
        return Ok(Vec::new());
    }

    let question_ids: Vec<Uuid> = questions
        .iter()
        .filter_map(|q| q.get("id").and_then(|id| id.as_str()).and_then(|s| Uuid::parse_str(s).ok()))
        .collect();

    // Batch Query 1: All choices
    let all_choices: Vec<question_choices::Model> = question_choices::Entity::find()
        .filter(question_choices::Column::QuestionId.is_in(question_ids.clone()))
        .order_by_asc(question_choices::Column::OrderIndex)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to fetch question choices: {}", e)))?;

    let mut choices_map: HashMap<Uuid, Vec<question_choices::Model>> = HashMap::new();
    for choice in all_choices {
        choices_map.entry(choice.question_id).or_insert_with(Vec::new).push(choice);
    }

    // Batch Query 2: Answer keys for all questions (contains both identification and enumeration answers)
    let all_answer_keys: Vec<answer_keys::Model> = answer_keys::Entity::find()
        .filter(answer_keys::Column::QuestionId.is_in(question_ids.clone()))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to fetch answer keys: {}", e)))?;

    let mut answer_keys_map: HashMap<Uuid, Vec<answer_keys::Model>> = HashMap::new();
    for key in all_answer_keys {
        answer_keys_map.entry(key.question_id).or_insert_with(Vec::new).push(key);
    }

    // Batch Query 3: Acceptable answers for all keys (teacher/admin only)
    let answer_key_ids: Vec<Uuid> = answer_keys_map
        .values()
        .flat_map(|keys| keys.iter().map(|key| key.id))
        .collect();

    let all_acceptable_answers: Vec<answer_key_acceptable_answers::Model> = if !answer_key_ids.is_empty() && user_role != "student" {
        answer_key_acceptable_answers::Entity::find()
            .filter(answer_key_acceptable_answers::Column::AnswerKeyId.is_in(answer_key_ids))
            .all(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to fetch acceptable answers: {}", e)))?
    } else {
        Vec::new()
    };

    let mut acceptable_answers_map: HashMap<Uuid, Vec<answer_key_acceptable_answers::Model>> = HashMap::new();
    for answer in all_acceptable_answers {
        acceptable_answers_map.entry(answer.answer_key_id).or_insert_with(Vec::new).push(answer);
    }

    // Build enriched question JSON per question
    let enriched: Vec<Value> = questions
        .into_iter()
        .map(|mut q| {
            let q_id = q.get("id")
                .and_then(|id| id.as_str())
                .and_then(|s| Uuid::parse_str(s).ok());

            if let Some(q_id) = q_id {
                let q_type = q.get("question_type").and_then(|v| v.as_str()).unwrap_or("");

                match q_type {
                    "multiple_choice" => {
                        let choices = choices_map.get(&q_id).map(|v| v.as_slice()).unwrap_or(&[]);
                        if user_role == "student" {
                            // Sanitized: is_correct intentionally absent
                            q["choices"] = json!(choices.iter().map(|c| json!({
                                "id": c.id.to_string(),
                                "choice_text": c.choice_text,
                                "order_index": c.order_index
                            })).collect::<Vec<_>>());
                        } else {
                            // Full: includes is_correct
                            q["choices"] = json!(choices.iter().map(|c| json!({
                                "id": c.id.to_string(),
                                "choice_text": c.choice_text,
                                "is_correct": c.is_correct,
                                "order_index": c.order_index
                            })).collect::<Vec<_>>());
                        }
                        q["correct_answers"] = json!([]);
                        q["enumeration_items"] = json!([]);
                    }
                    "identification" => {
                        q["choices"] = json!([]);
                        if user_role != "student" {
                            let keys = answer_keys_map.get(&q_id).map(|v| v.as_slice()).unwrap_or(&[]);
                            q["answer_keys"] = json!(keys.iter().map(|key| {
                                let answers = acceptable_answers_map.get(&key.id).map(|v| v.as_slice()).unwrap_or(&[]);
                                json!({
                                    "id": key.id.to_string(),
                                    "acceptable_answers": answers.iter().map(|a| a.answer_text.clone()).collect::<Vec<_>>()
                                })
                            }).collect::<Vec<_>>());
                        } else {
                            q["answer_keys"] = json!([]);
                        }
                        q["enumeration_items"] = json!([]);
                    }
                    "enumeration" => {
                        q["choices"] = json!([]);
                        let keys = answer_keys_map.get(&q_id).map(|v| v.as_slice()).unwrap_or(&[]);
                        q["enumeration_items"] = json!(keys.iter().enumerate().map(|(idx, key)| {
                            let answers = acceptable_answers_map.get(&key.id).map(|v| v.as_slice()).unwrap_or(&[]);
                            if user_role != "student" {
                                json!({
                                    "id": key.id.to_string(),
                                    "order_index": idx,
                                    "acceptable_answers": answers.iter().map(|a| json!({
                                        "id": a.id.to_string(),
                                        "answer_text": a.answer_text
                                    })).collect::<Vec<_>>()
                                })
                            } else {
                                json!({
                                    "id": key.id.to_string(),
                                    "order_index": idx,
                                    "acceptable_answers": []
                                })
                            }
                        }).collect::<Vec<_>>());
                    }
                    _ => {}
                }
            }
            q
        })
        .collect();

    Ok(enriched)
}
