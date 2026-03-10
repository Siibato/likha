use sea_orm::*;
use serde_json::{json, Value};
use std::collections::HashMap;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::{
    question_choices, question_correct_answers, enumeration_items, enumeration_item_answers,
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

    // Batch Query 2: Correct answers (teacher/admin only)
    let all_correct_answers: Vec<question_correct_answers::Model> = if user_role != "student" {
        question_correct_answers::Entity::find()
            .filter(question_correct_answers::Column::QuestionId.is_in(question_ids.clone()))
            .all(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to fetch correct answers: {}", e)))?
    } else {
        Vec::new()
    };

    let mut correct_answers_map: HashMap<Uuid, Vec<question_correct_answers::Model>> = HashMap::new();
    for answer in all_correct_answers {
        correct_answers_map.entry(answer.question_id).or_insert_with(Vec::new).push(answer);
    }

    // Batch Query 3 & 4: Enumeration items and their acceptable answers
    let all_enum_items: Vec<enumeration_items::Model> = enumeration_items::Entity::find()
        .filter(enumeration_items::Column::QuestionId.is_in(question_ids.clone()))
        .order_by_asc(enumeration_items::Column::OrderIndex)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to fetch enumeration items: {}", e)))?;

    let mut enum_items_map: HashMap<Uuid, Vec<enumeration_items::Model>> = HashMap::new();
    for item in all_enum_items {
        enum_items_map.entry(item.question_id).or_insert_with(Vec::new).push(item);
    }

    let enum_item_ids: Vec<Uuid> = enum_items_map
        .values()
        .flat_map(|items| items.iter().map(|item| item.id))
        .collect();

    let all_enum_answers: Vec<enumeration_item_answers::Model> = if !enum_item_ids.is_empty() && user_role != "student" {
        enumeration_item_answers::Entity::find()
            .filter(enumeration_item_answers::Column::EnumerationItemId.is_in(enum_item_ids))
            .all(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to fetch enumeration item answers: {}", e)))?
    } else {
        Vec::new()
    };

    let mut enum_answers_map: HashMap<Uuid, Vec<enumeration_item_answers::Model>> = HashMap::new();
    for answer in all_enum_answers {
        enum_answers_map.entry(answer.enumeration_item_id).or_insert_with(Vec::new).push(answer);
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
                            let answers = correct_answers_map.get(&q_id).map(|v| v.as_slice()).unwrap_or(&[]);
                            q["correct_answers"] = json!(answers.iter().map(|a| json!({
                                "id": a.id.to_string(),
                                "answer_text": a.answer_text
                            })).collect::<Vec<_>>());
                        } else {
                            q["correct_answers"] = json!([]);
                        }
                        q["enumeration_items"] = json!([]);
                    }
                    "enumeration" => {
                        q["choices"] = json!([]);
                        q["correct_answers"] = json!([]);
                        let items = enum_items_map.get(&q_id).map(|v| v.as_slice()).unwrap_or(&[]);
                        if user_role != "student" {
                            // Teacher: full items with acceptable answers
                            q["enumeration_items"] = json!(items.iter().map(|item| {
                                let answers = enum_answers_map.get(&item.id).map(|v| v.as_slice()).unwrap_or(&[]);
                                json!({
                                    "id": item.id.to_string(),
                                    "order_index": item.order_index,
                                    "acceptable_answers": answers.iter().map(|a| json!({
                                        "id": a.id.to_string(),
                                        "answer_text": a.answer_text
                                    })).collect::<Vec<_>>()
                                })
                            }).collect::<Vec<_>>());
                        } else {
                            // Student: only count of items needed (no items, no answers)
                            q["enumeration_count"] = json!(items.len());
                            q["enumeration_items"] = json!([]);
                        }
                    }
                    _ => {}
                }
            }
            q
        })
        .collect();

    Ok(enriched)
}
