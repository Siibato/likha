use chrono::{Duration, NaiveDateTime, Utc};
use sea_orm::*;
use serde_json::{json, Value};
use std::collections::HashMap;
use std::sync::Arc;
use uuid::Uuid;

use crate::db::repositories::manifest_repository::ManifestRepository;
use crate::services::entitlement::EntitlementService;
use crate::utils::{AppError, AppResult};
use ::entity::{
    question_choices, question_correct_answers, enumeration_items, enumeration_item_answers,
};

/// Request for delta sync
#[derive(Debug, Clone, serde::Deserialize)]
pub struct DeltaRequest {
    pub device_id: String,
    pub last_sync_at: String, // ISO8601
    pub data_expiry_at: Option<String>,
}

/// Entity deltas (updated and deleted records)
#[derive(Debug, Clone, serde::Serialize)]
pub struct EntityDeltas {
    pub updated: Vec<Value>,
    pub deleted: Vec<String>,
}

/// Payload of deltas
#[derive(Debug, Clone, serde::Serialize)]
pub struct DeltaPayload {
    pub classes: EntityDeltas,
    pub enrollments: EntityDeltas,
    pub assessments: EntityDeltas,
    pub questions: EntityDeltas,
    pub assessment_submissions: EntityDeltas,
    pub assignments: EntityDeltas,
    pub assignment_submissions: EntityDeltas,
    pub learning_materials: EntityDeltas,
}

/// Response variants
#[derive(Debug, Clone, serde::Serialize)]
#[serde(untagged)]
pub enum DeltaResponse {
    DataExpired {
        status: String,
        message: String,
    },
    Deltas {
        sync_token: String,
        server_time: String,
        deltas: DeltaPayload,
    },
}

/// Service for delta sync
pub struct SyncDeltaService {
    entitlement_service: Arc<EntitlementService>,
    manifest_repo: ManifestRepository,
    db: DatabaseConnection,
}

impl SyncDeltaService {
    pub fn new(
        entitlement_service: Arc<EntitlementService>,
        manifest_repo: ManifestRepository,
        db: DatabaseConnection,
    ) -> Self {
        Self {
            entitlement_service,
            manifest_repo,
            db,
        }
    }

    /// Get delta sync data since last_sync_at
    pub async fn get_deltas(
        &self,
        user_id: Uuid,
        user_role: &str,
        request: DeltaRequest,
    ) -> AppResult<DeltaResponse> {
        tracing::info!(
            "Delta sync initiated for user_id={}, role={}, device_id={}, last_sync_at={}",
            user_id,
            user_role,
            request.device_id,
            request.last_sync_at
        );

        // Step 1: Parse last_sync_at (ISO8601 format)
        let last_sync_at: NaiveDateTime = request
            .last_sync_at
            .parse::<chrono::DateTime<Utc>>()
            .map_err(|e| AppError::BadRequest(format!("Invalid last_sync_at: {}", e)))?
            .naive_utc();

        // Step 2: Check if data is expired (> 30 days)
        let now = Utc::now();
        let expiry_threshold = now - Duration::days(30);
        if last_sync_at < expiry_threshold.naive_utc() {
            tracing::warn!(
                "Data expired for user_id={}. last_sync_at={}, expiry_threshold={}",
                user_id,
                last_sync_at,
                expiry_threshold.naive_utc()
            );
            return Ok(DeltaResponse::DataExpired {
                status: "data_expired".to_string(),
                message: "Data is stale. Please perform a full sync.".to_string(),
            });
        }

        // Step 3: Get user's entitled IDs
        tracing::debug!("Fetching user manifest for user_id={}", user_id);
        let manifest = self
            .entitlement_service
            .get_user_manifest(user_id, user_role)
            .await?;

        // Step 4: Query for deltas per entity type
        tracing::debug!("Fetching class deltas since {}", last_sync_at);
        let classes = self
            .manifest_repo
            .get_classes_since(manifest.classes.iter().map(|e| e.id).collect(), last_sync_at)
            .await?;
        tracing::debug!("Got {} class deltas", classes.len());

        tracing::debug!("Fetching enrollment deltas since {}", last_sync_at);
        let enrollments = self
            .manifest_repo
            .get_enrollments_since(
                manifest.enrollments.iter().map(|e| e.id).collect(),
                last_sync_at,
            )
            .await?;
        tracing::debug!("Got {} enrollment deltas", enrollments.len());

        tracing::debug!("Fetching assessment deltas since {}", last_sync_at);
        let assessments = self
            .manifest_repo
            .get_assessments_since(
                manifest.assessments.iter().map(|e| e.id).collect(),
                last_sync_at,
            )
            .await?;
        tracing::debug!("Got {} assessment deltas", assessments.len());

        let question_ids: Vec<Uuid> = manifest.assessment_questions.iter().map(|e| e.id).collect();
        tracing::debug!("Fetching {} question deltas since {}", question_ids.len(), last_sync_at);
        let questions = if question_ids.is_empty() {
            Vec::new()
        } else {
            let raw_questions = self.manifest_repo
                .get_questions_since(question_ids, last_sync_at)
                .await?;
            // Enrich questions with nested data (choices, correct answers, enumeration items)
            self.enrich_questions(raw_questions, user_role).await?
        };
        tracing::debug!("Got {} question deltas", questions.len());

        let assessment_submission_ids: Vec<Uuid> =
            manifest.assessment_submissions.iter().map(|e| e.id).collect();
        tracing::debug!("Fetching {} assessment submission deltas since {}", assessment_submission_ids.len(), last_sync_at);
        let assessment_submissions = if assessment_submission_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo
                .get_assessment_submissions_since(user_id, assessment_submission_ids, last_sync_at)
                .await?
        };
        tracing::debug!("Got {} assessment submission deltas", assessment_submissions.len());

        tracing::debug!("Fetching assignment deltas since {}", last_sync_at);
        let assignments = self
            .manifest_repo
            .get_assignments_since(
                manifest.assignments.iter().map(|e| e.id).collect(),
                last_sync_at,
            )
            .await?;
        tracing::debug!("Got {} assignment deltas", assignments.len());

        let assignment_submission_ids: Vec<Uuid> =
            manifest.assignment_submissions.iter().map(|e| e.id).collect();
        tracing::debug!("Fetching {} assignment submission deltas since {}", assignment_submission_ids.len(), last_sync_at);
        let assignment_submissions = if assignment_submission_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo
                .get_assignment_submissions_since(user_id, assignment_submission_ids, last_sync_at)
                .await?
        };
        tracing::debug!("Got {} assignment submission deltas", assignment_submissions.len());

        tracing::debug!("Fetching learning material deltas since {}", last_sync_at);
        let learning_materials = self
            .manifest_repo
            .get_materials_since(
                manifest.learning_materials.iter().map(|e| e.id).collect(),
                last_sync_at,
            )
            .await?;
        tracing::debug!("Got {} learning material deltas", learning_materials.len());

        // Step 5: Separate updated vs deleted for each entity type
        let classes_deltas = Self::separate_deltas(classes);
        let enrollments_deltas = Self::separate_deltas(enrollments);
        let assessments_deltas = Self::separate_deltas(assessments);
        let questions_deltas = Self::separate_deltas(questions);
        let assessment_submissions_deltas = Self::separate_deltas(assessment_submissions);
        let assignments_deltas = Self::separate_deltas(assignments);
        let assignment_submissions_deltas = Self::separate_deltas(assignment_submissions);
        let learning_materials_deltas = Self::separate_deltas(learning_materials);

        let now = Utc::now();
        let sync_token = now.to_rfc3339();
        let server_time = now.to_rfc3339();

        tracing::info!(
            "Delta sync completed for user_id={}. Classes: {} updated, {} deleted. Assignments: {} updated, {} deleted.",
            user_id,
            classes_deltas.updated.len(),
            classes_deltas.deleted.len(),
            assignments_deltas.updated.len(),
            assignments_deltas.deleted.len()
        );

        Ok(DeltaResponse::Deltas {
            sync_token,
            server_time,
            deltas: DeltaPayload {
                classes: classes_deltas,
                enrollments: enrollments_deltas,
                assessments: assessments_deltas,
                questions: questions_deltas,
                assessment_submissions: assessment_submissions_deltas,
                assignments: assignments_deltas,
                assignment_submissions: assignment_submissions_deltas,
                learning_materials: learning_materials_deltas,
            },
        })
    }

    /// Enrich questions with nested choices, correct_answers, and enumeration_items
    async fn enrich_questions(&self, questions: Vec<Value>, user_role: &str) -> AppResult<Vec<Value>> {
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
            .all(&self.db)
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
                .all(&self.db)
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
            .all(&self.db)
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
                .all(&self.db)
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

    /// Separate records into updated and deleted based on deleted_at field
    fn separate_deltas(records: Vec<Value>) -> EntityDeltas {
        let mut updated = Vec::new();
        let mut deleted = Vec::new();

        for record in records {
            let deleted_at = record.get("deleted_at");
            let id = record
                .get("id")
                .and_then(|v| v.as_str())
                .unwrap_or("unknown");

            if let Some(deleted_at_val) = deleted_at {
                if !deleted_at_val.is_null() {
                    // This is a soft-deleted record
                    deleted.push(id.to_string());
                    continue;
                }
            }
            // This is an updated record
            updated.push(record);
        }

        EntityDeltas { updated, deleted }
    }
}
