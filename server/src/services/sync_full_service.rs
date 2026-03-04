use chrono::Utc;
use sea_orm::*;
use serde_json::{json, Value};
use std::collections::{HashMap, HashSet};
use std::sync::Arc;
use uuid::Uuid;

use crate::db::repositories::manifest_repository::ManifestRepository;
use crate::services::entitlement::EntitlementService;
use crate::utils::{AppResult, AppError};
use ::entity::{
    question_choices, question_correct_answers, enumeration_items, enumeration_item_answers,
    submission_answers, submission_answer_choices, submission_enumeration_answers,
    material_files, submission_files, assessment_questions,
};

/// Request for full sync
#[derive(Debug, Clone, serde::Deserialize)]
pub struct FullSyncRequest {
    pub device_id: String,
}

/// Response for full sync
#[derive(Debug, Clone, serde::Serialize)]
pub struct FullSyncResponse {
    pub sync_token: String,
    pub server_time: String,
    pub user: Option<Value>,
    pub classes: Vec<Value>,
    pub enrollments: Vec<Value>,
    pub enrolled_students: Vec<Value>,
    pub assessments: Vec<Value>,
    pub questions: Vec<Value>,
    pub assessment_submissions: Vec<Value>,
    pub assignments: Vec<Value>,
    pub assignment_submissions: Vec<Value>,
    pub learning_materials: Vec<Value>,
    pub material_files: Vec<Value>,
    pub submission_files: Vec<Value>,
}

/// Service for full sync on login
pub struct SyncFullService {
    entitlement_service: Arc<EntitlementService>,
    manifest_repo: ManifestRepository,
    db: DatabaseConnection,
}

impl SyncFullService {
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

    /// Get full sync data for user
    pub async fn get_full_sync(
        &self,
        user_id: Uuid,
        user_role: &str,
        request: FullSyncRequest,
    ) -> AppResult<FullSyncResponse> {
        tracing::debug!(
            "Starting full sync for user_id={}, role={}, device_id={}",
            user_id,
            user_role,
            request.device_id
        );

        // Step 1: Get all records user is entitled to
        tracing::debug!("Fetching user manifest for user_id={}", user_id);
        let manifest = self
            .entitlement_service
            .get_user_manifest(user_id, user_role)
            .await?;

        tracing::debug!(
            "User manifest retrieved: classes={}, enrollments={}, assessments={}, assignments={}",
            manifest.classes.len(),
            manifest.enrollments.len(),
            manifest.assessments.len(),
            manifest.assignments.len()
        );

        // Step 2: Fetch full records for each entity type
        tracing::debug!("Fetching classes for user_id={}", user_id);
        let classes = self
            .manifest_repo
            .get_classes_paginated(
                manifest.classes.iter().map(|e| e.id).collect(),
                10000,
            )
            .await?
            .records;
        tracing::debug!("Fetched {} classes", classes.len());

        tracing::debug!("Fetching enrollments for user_id={}", user_id);
        let enrollment_data = self
            .manifest_repo
            .get_enrollments_paginated(
                manifest.enrollments.iter().map(|e| e.id).collect(),
                10000,
            )
            .await?;
        let enrollments = enrollment_data.records.clone();
        tracing::debug!("Fetched {} enrollments", enrollments.len());

        // Extract unique student IDs from enrollments (for manifest)
        let student_ids: Vec<Uuid> = enrollment_data
            .records
            .iter()
            .filter_map(|e| {
                e.get("student_id")
                    .and_then(|id| id.as_str())
                    .and_then(|id_str| uuid::Uuid::parse_str(id_str).ok())
            })
            .collect::<HashSet<_>>()
            .into_iter()
            .collect();

        // Role-aware enrolled_students filtering
        let enrolled_students = match user_role {
            "student" => {
                // Privacy: students must NOT see other students' profiles
                // (teacher name is already in classes.teacher_full_name)
                tracing::debug!("Student role detected: not fetching enrolled_students list");
                Vec::new()
            }
            _ => {
                // Teachers and admins get full student list for grading/management
                tracing::debug!("Fetching {} enrolled students for user_id={}", student_ids.len(), user_id);
                if student_ids.is_empty() {
                    Vec::new()
                } else {
                    self.manifest_repo
                        .get_users_paginated(student_ids, 10000)
                        .await?
                        .records
                }
            }
        };
        tracing::debug!("Fetched {} enrolled students", enrolled_students.len());

        tracing::debug!("Fetching assessments for user_id={}", user_id);
        let assessments = self
            .manifest_repo
            .get_assessments_paginated(
                manifest.assessments.iter().map(|e| e.id).collect(),
                10000,
            )
            .await?
            .records;
        tracing::debug!("Fetched {} assessments", assessments.len());

        let question_ids: Vec<Uuid> = manifest.assessment_questions.iter().map(|e| e.id).collect();
        tracing::debug!("Fetching {} questions for user_id={}", question_ids.len(), user_id);
        let questions = if question_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo
                .get_questions_paginated(question_ids, 10000)
                .await?
                .records
        };
        tracing::debug!("Fetched {} questions", questions.len());

        // Role-aware assessment submissions
        let assessment_submission_ids: Vec<Uuid> =
            manifest.assessment_submissions.iter().map(|e| e.id).collect();
        tracing::debug!("Fetching {} assessment submissions for user_id={}", assessment_submission_ids.len(), user_id);
        let assessment_submissions = if assessment_submission_ids.is_empty() {
            Vec::new()
        } else {
            match user_role {
                "student" => {
                    // Students: own submissions only (manifest already filtered by student_id)
                    self.manifest_repo
                        .get_assessment_submissions_paginated(user_id, assessment_submission_ids, 10000)
                        .await?
                        .records
                }
                _ => {
                    // Teachers/admins: ALL submissions for accessible assessments
                    let assessment_ids: Vec<Uuid> = manifest.assessments.iter().map(|a| a.id).collect();
                    self.get_all_assessment_submissions_for_assessments(&assessment_ids, 10000)
                        .await?
                }
            }
        };
        tracing::debug!("Fetched {} assessment submissions", assessment_submissions.len());

        tracing::debug!("Fetching assignments for user_id={}", user_id);
        let assignments = self
            .manifest_repo
            .get_assignments_paginated(
                manifest.assignments.iter().map(|e| e.id).collect(),
                10000,
            )
            .await?
            .records;
        tracing::debug!("Fetched {} assignments", assignments.len());

        // Role-aware assignment submissions
        let assignment_submission_ids: Vec<Uuid> =
            manifest.assignment_submissions.iter().map(|e| e.id).collect();
        tracing::debug!("Fetching {} assignment submissions for user_id={}", assignment_submission_ids.len(), user_id);
        let assignment_submissions = if assignment_submission_ids.is_empty() {
            Vec::new()
        } else {
            match user_role {
                "student" => {
                    // Students: own submissions only
                    self.manifest_repo
                        .get_assignment_submissions_paginated(user_id, assignment_submission_ids, 10000)
                        .await?
                        .records
                }
                _ => {
                    // Teachers/admins: ALL submissions for accessible assignments
                    let assignment_ids: Vec<Uuid> = manifest.assignments.iter().map(|a| a.id).collect();
                    self.get_all_assignment_submissions_for_assignments(&assignment_ids, 10000)
                        .await?
                }
            }
        };
        tracing::debug!("Fetched {} assignment submissions", assignment_submissions.len());

        tracing::debug!("Fetching learning materials for user_id={}", user_id);
        let learning_materials = self
            .manifest_repo
            .get_materials_paginated(
                manifest.learning_materials.iter().map(|e| e.id).collect(),
                10000,
            )
            .await?
            .records;
        tracing::debug!("Fetched {} learning materials", learning_materials.len());

        // Enrich questions with nested data (choices, correct_answers, enumeration_items)
        tracing::debug!("Enriching {} questions with nested data", questions.len());
        let enriched_questions = self.enrich_questions(questions, user_role).await?;
        tracing::debug!("Enriched questions completed");

        // Enrich assessment submissions with nested answers
        tracing::debug!("Enriching {} assessment submissions with nested answers", assessment_submissions.len());
        let enriched_assessment_submissions = self.enrich_assessment_submissions(assessment_submissions).await?;
        tracing::debug!("Enriched assessment submissions completed");

        // Fetch material_files (no binary data included)
        let material_ids: Vec<Uuid> = learning_materials
            .iter()
            .filter_map(|m| m.get("id").and_then(|id| id.as_str()).and_then(|s| Uuid::parse_str(s).ok()))
            .collect();
        tracing::debug!("Fetching material files for {} materials", material_ids.len());
        let material_files = if material_ids.is_empty() {
            Vec::new()
        } else {
            material_files::Entity::find()
                .filter(material_files::Column::MaterialId.is_in(material_ids))
                .all(&self.db)
                .await
                .map_err(|e| crate::utils::AppError::InternalServerError(format!("Failed to fetch material files: {}", e)))?
                .into_iter()
                .map(|f| json!({
                    "id": f.id.to_string(),
                    "material_id": f.material_id.to_string(),
                    "file_name": f.file_name,
                    "file_type": f.file_type,
                    "file_size": f.file_size,
                    "uploaded_at": f.uploaded_at.to_string(),
                }))
                .collect()
        };
        tracing::debug!("Fetched {} material files", material_files.len());

        // Fetch submission_files (no binary data included)
        let submission_ids: Vec<Uuid> = enriched_assessment_submissions
            .iter()
            .filter_map(|s| s.get("id").and_then(|id| id.as_str()).and_then(|s| Uuid::parse_str(s).ok()))
            .collect();
        tracing::debug!("Fetching submission files for {} submissions", submission_ids.len());
        let submission_files = if submission_ids.is_empty() {
            Vec::new()
        } else {
            submission_files::Entity::find()
                .filter(submission_files::Column::SubmissionId.is_in(submission_ids))
                .all(&self.db)
                .await
                .map_err(|e| crate::utils::AppError::InternalServerError(format!("Failed to fetch submission files: {}", e)))?
                .into_iter()
                .map(|f| json!({
                    "id": f.id.to_string(),
                    "submission_id": f.submission_id.to_string(),
                    "file_name": f.file_name,
                    "file_type": f.file_type,
                    "file_size": f.file_size,
                    "uploaded_at": f.uploaded_at.to_string(),
                }))
                .collect()
        };
        tracing::debug!("Fetched {} submission files", submission_files.len());

        // Fetch the logged-in user's own record for sync response
        let user = self.manifest_repo
            .get_users_paginated(vec![user_id], 1)
            .await?
            .records
            .into_iter()
            .next();

        let now = Utc::now();
        let sync_token = now.to_rfc3339();
        let server_time = now.to_rfc3339();

        tracing::info!(
            "Full sync completed successfully for user_id={}. Classes: {}, Enrollments: {}, Students: {}, Assessments: {}, Assignments: {}, Materials: {}",
            user_id,
            classes.len(),
            enrollments.len(),
            enrolled_students.len(),
            assessments.len(),
            assignments.len(),
            learning_materials.len()
        );

        Ok(FullSyncResponse {
            sync_token,
            server_time,
            user,
            classes,
            enrollments,
            enrolled_students,
            assessments,
            questions: enriched_questions,
            assessment_submissions: enriched_assessment_submissions,
            assignments,
            assignment_submissions,
            learning_materials,
            material_files,
            submission_files,
        })
    }

    /// Fetch all assessment submissions for given assessments
    async fn get_all_assessment_submissions_for_assessments(
        &self,
        assessment_ids: &[Uuid],
        limit: i64,
    ) -> AppResult<Vec<Value>> {
        if assessment_ids.is_empty() {
            return Ok(Vec::new());
        }
        self.manifest_repo
            .get_all_assessment_submissions_for_assessments(assessment_ids.to_vec(), limit)
            .await
            .map(|r| r.records)
    }

    /// Fetch all assignment submissions for given assignments
    async fn get_all_assignment_submissions_for_assignments(
        &self,
        assignment_ids: &[Uuid],
        limit: i64,
    ) -> AppResult<Vec<Value>> {
        if assignment_ids.is_empty() {
            return Ok(Vec::new());
        }
        self.manifest_repo
            .get_all_assignment_submissions_for_assignments(assignment_ids.to_vec(), limit)
            .await
            .map(|r| r.records)
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

    /// Enrich assessment submissions with nested answers
    async fn enrich_assessment_submissions(&self, submissions: Vec<Value>) -> AppResult<Vec<Value>> {
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
            .all(&self.db)
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
                .all(&self.db)
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
                .all(&self.db)
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
                .all(&self.db)
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
                .all(&self.db)
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
}
