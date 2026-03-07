use sea_orm::*;
use serde_json::{json, Value};
use std::collections::{HashMap, HashSet};
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::{
    submission_answers, submission_answer_choices,
    submission_enumeration_answers, assessment_questions, question_choices,
};

/// Enriches assessment submissions with nested answer details.
/// Performs 5 batch DB queries to assemble the full submission view.
pub async fn enrich_assessment_submissions(
    db: &DatabaseConnection,
    submissions: Vec<Value>,
) -> AppResult<Vec<Value>> {
    if submissions.is_empty() {
        return Ok(Vec::new());
    }

    let submission_ids: Vec<Uuid> = submissions
        .iter()
        .filter_map(|s| s.get("id").and_then(|id| id.as_str()).and_then(|s| Uuid::parse_str(s).ok()))
        .collect();

    // Batch Query 1: All submission_answers
    let all_sub_answers: Vec<submission_answers::Model> = submission_answers::Entity::find()
        .filter(submission_answers::Column::SubmissionId.is_in(submission_ids))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to fetch submission answers: {}", e)))?;

    let mut answers_by_submission: HashMap<Uuid, Vec<submission_answers::Model>> = HashMap::new();
    for answer in all_sub_answers.iter() {
        answers_by_submission
            .entry(answer.submission_id)
            .or_insert_with(Vec::new)
            .push(answer.clone());
    }

    // Batch Query 2: All submission_answer_choices
    let answer_ids: Vec<Uuid> = all_sub_answers.iter().map(|a| a.id).collect();
    let all_selected_choices: Vec<submission_answer_choices::Model> = if !answer_ids.is_empty() {
        submission_answer_choices::Entity::find()
            .filter(submission_answer_choices::Column::SubmissionAnswerId.is_in(answer_ids.clone()))
            .all(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to fetch submission answer choices: {}", e)))?
    } else {
        Vec::new()
    };

    // Compute unique choice IDs before consuming the vector
    let unique_choice_ids: Vec<Uuid> = all_selected_choices
        .iter()
        .map(|c| c.choice_id)
        .collect::<HashSet<_>>()
        .into_iter()
        .collect();

    let mut selected_choices_by_answer: HashMap<Uuid, Vec<submission_answer_choices::Model>> = HashMap::new();
    for choice in all_selected_choices {
        selected_choices_by_answer
            .entry(choice.submission_answer_id)
            .or_insert_with(Vec::new)
            .push(choice);
    }

    // Batch Query 3: All submission_enumeration_answers
    let all_enum_sub_answers: Vec<submission_enumeration_answers::Model> = if !answer_ids.is_empty() {
        submission_enumeration_answers::Entity::find()
            .filter(submission_enumeration_answers::Column::SubmissionAnswerId.is_in(answer_ids))
            .all(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to fetch submission enumeration answers: {}", e)))?
    } else {
        Vec::new()
    };

    let mut enum_answers_by_answer: HashMap<Uuid, Vec<submission_enumeration_answers::Model>> = HashMap::new();
    for answer in all_enum_sub_answers {
        enum_answers_by_answer
            .entry(answer.submission_answer_id)
            .or_insert_with(Vec::new)
            .push(answer);
    }

    // Batch Query 4: Question metadata (question_text, question_type, points)
    let unique_q_ids: Vec<Uuid> = all_sub_answers
        .iter()
        .map(|a| a.question_id)
        .collect::<HashSet<_>>()
        .into_iter()
        .collect();

    let question_meta: HashMap<Uuid, (String, String, i32)> = if !unique_q_ids.is_empty() {
        assessment_questions::Entity::find()
            .filter(assessment_questions::Column::Id.is_in(unique_q_ids))
            .all(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to fetch question metadata: {}", e)))?
            .into_iter()
            .map(|q| (q.id, (q.question_text, q.question_type, q.points)))
            .collect()
    } else {
        HashMap::new()
    };

    // Batch Query 5: Choice text for selected_choices display (unique_choice_ids computed above)
    let choice_meta: HashMap<Uuid, (String, bool)> = if !unique_choice_ids.is_empty() {
        question_choices::Entity::find()
            .filter(question_choices::Column::Id.is_in(unique_choice_ids))
            .all(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to fetch choice metadata: {}", e)))?
            .into_iter()
            .map(|c| (c.id, (c.choice_text, c.is_correct)))
            .collect()
    } else {
        HashMap::new()
    };

    // Build enriched submission JSON
    let enriched: Vec<Value> = submissions
        .into_iter()
        .map(|mut sub| {
            let sub_id = sub.get("id")
                .and_then(|id| id.as_str())
                .and_then(|s| Uuid::parse_str(s).ok());

            if let Some(sub_id) = sub_id {
                let answers_for_sub = answers_by_submission.get(&sub_id).map(|v| v.as_slice()).unwrap_or(&[]);

                let answers_json: Vec<Value> = answers_for_sub
                    .iter()
                    .map(|ans| {
                        let (q_text, q_type, q_points) = question_meta
                            .get(&ans.question_id)
                            .map(|(t, y, p)| (t.as_str(), y.as_str(), *p))
                            .unwrap_or(("", "", 0));

                        // Build selected_choices
                        let selected_choices: Vec<Value> = selected_choices_by_answer
                            .get(&ans.id)
                            .map(|v| v.as_slice())
                            .unwrap_or(&[])
                            .iter()
                            .map(|sc| {
                                let (choice_text, is_correct) = choice_meta
                                    .get(&sc.choice_id)
                                    .map(|(t, c)| (t.as_str(), *c))
                                    .unwrap_or(("", false));
                                json!({
                                    "choice_id": sc.choice_id.to_string(),
                                    "choice_text": choice_text,
                                    "is_correct": is_correct
                                })
                            })
                            .collect();

                        // Build enumeration_answers
                        let enum_answers: Vec<Value> = enum_answers_by_answer
                            .get(&ans.id)
                            .map(|v| v.as_slice())
                            .unwrap_or(&[])
                            .iter()
                            .map(|ea| json!({
                                "id": ea.id.to_string(),
                                "answer_text": ea.answer_text,
                                "matched_item_id": ea.matched_item_id.map(|id| id.to_string()),
                                "is_auto_correct": ea.is_auto_correct,
                                "is_override_correct": ea.is_override_correct
                            }))
                            .collect();

                        json!({
                            "id": ans.id.to_string(),
                            "question_id": ans.question_id.to_string(),
                            "question_text": q_text,
                            "question_type": q_type,
                            "points": q_points,
                            "answer_text": ans.answer_text,
                            "selected_choices": selected_choices,
                            "enumeration_answers": enum_answers,
                            "is_auto_correct": ans.is_auto_correct,
                            "is_override_correct": ans.is_override_correct,
                            "points_awarded": ans.points_awarded
                        })
                    })
                    .collect();

                sub["answers"] = json!(answers_json);
            }
            sub
        })
        .collect();

    Ok(enriched)
}
