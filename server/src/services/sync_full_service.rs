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
    pub class_ids: Option<Vec<String>>,  // empty/null = base data only; non-empty = batch request
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
    pub assessment_statistics: Vec<Value>,
    pub student_results: Vec<Value>,
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
        let class_ids = request.class_ids.unwrap_or_default();
        let is_base_request = class_ids.is_empty();

        tracing::debug!(
            "Starting full sync for user_id={}, role={}, device_id={}, base_request={}",
            user_id,
            user_role,
            request.device_id,
            is_base_request
        );

        // Always get full manifest for entitlement and filtering
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

        // Fetch the logged-in user's own record
        let user = self.manifest_repo
            .get_users_paginated(vec![user_id], 1)
            .await?
            .records
            .into_iter()
            .next();

        // BASE REQUEST: Return only structural data, no entity content
        if is_base_request {
            tracing::debug!("BASE REQUEST detected for user_id={} - returning only structural data", user_id);

            // Fetch classes and enrollments (always needed)
            tracing::debug!("Fetching classes for user_id={}", user_id);
            let classes = self
                .manifest_repo
                .get_classes_paginated(
                    manifest.classes.iter().map(|e| e.id).collect(),
                    10000,
                )
                .await?
                .records;
            tracing::debug!("BASE REQUEST: Fetched {} classes", classes.len());

            tracing::debug!("Fetching enrollments for user_id={}", user_id);
            let enrollment_data = self
                .manifest_repo
                .get_enrollments_paginated(
                    manifest.enrollments.iter().map(|e| e.id).collect(),
                    10000,
                )
                .await?;
            let enrollments = enrollment_data.records.clone();
            tracing::debug!("BASE REQUEST: Fetched {} enrollments", enrollments.len());

            // Extract enrolled students (role-aware)
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

            let enrolled_students = match user_role {
                "student" => Vec::new(),
                _ => {
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

            let now = Utc::now();
            let sync_token = now.to_rfc3339();
            let server_time = now.to_rfc3339();

            return Ok(FullSyncResponse {
                sync_token,
                server_time,
                user,
                classes,
                enrollments,
                enrolled_students,
                assessments: vec![],
                questions: vec![],
                assessment_submissions: vec![],
                assignments: vec![],
                assignment_submissions: vec![],
                learning_materials: vec![],
                material_files: vec![],
                submission_files: vec![],
                assessment_statistics: vec![],
                student_results: vec![],
            });
        }

        // BATCH REQUEST: Filter manifest by requested class_ids and fetch entity data
        tracing::debug!("BATCH REQUEST detected for user_id={}, role={} with {} class_ids", user_id, user_role, class_ids.len());

        // Security: intersect requested class_ids with entitled class_ids
        let entitled_class_ids: std::collections::HashSet<Uuid> = manifest.classes.iter().map(|e| e.id).collect();
        let batch_class_ids: Vec<Uuid> = class_ids
            .iter()
            .filter_map(|id| Uuid::parse_str(id).ok())
            .filter(|id| entitled_class_ids.contains(id))
            .collect();

        if batch_class_ids.is_empty() {
            tracing::warn!("All requested class_ids are invalid for user_id={}", user_id);
            let now = Utc::now();
            return Ok(FullSyncResponse {
                sync_token: now.to_rfc3339(),
                server_time: now.to_rfc3339(),
                user: None,
                classes: vec![],
                enrollments: vec![],
                enrolled_students: vec![],
                assessments: vec![],
                questions: vec![],
                assessment_submissions: vec![],
                assignments: vec![],
                assignment_submissions: vec![],
                learning_materials: vec![],
                material_files: vec![],
                submission_files: vec![],
                assessment_statistics: vec![],
                student_results: vec![],
            });
        }

        // Get filtered assessment IDs (for the batch classes)
        let batch_assessment_ids: Vec<Uuid> = manifest.assessments
            .iter()
            .filter(|_a| true) // Assessment IDs are already filtered by entitlement service
            .map(|e| e.id)
            .collect();

        let batch_assignment_ids: Vec<Uuid> = manifest.assignments
            .iter()
            .filter(|_a| true) // Assignment IDs are already filtered by entitlement service
            .map(|e| e.id)
            .collect();

        let batch_material_ids: Vec<Uuid> = manifest.learning_materials
            .iter()
            .filter(|_m| true) // Material IDs are already filtered by entitlement service
            .map(|e| e.id)
            .collect();

        let question_ids: Vec<Uuid> = manifest.assessment_questions.iter().map(|e| e.id).collect();
        tracing::debug!("BATCH REQUEST: Found {} question_ids in manifest for {} assessments",
            question_ids.len(), batch_assessment_ids.len());

        if question_ids.is_empty() {
            tracing::debug!("No questions found in manifest for assessments");
        }

        // Fetch enrollments for batch classes (needed for full offline support)
        let batch_enrollment_ids: Vec<Uuid> = manifest.enrollments
            .iter()
            .map(|e| e.id)
            .collect();

        let batch_enrollment_data = if batch_enrollment_ids.is_empty() {
            crate::db::repositories::manifest_repository::PaginatedRecords {
                records: Vec::new(),
                has_more: false,
            }
        } else {
            self.manifest_repo
                .get_enrollments_paginated(batch_enrollment_ids, 10000)
                .await?
        };
        let batch_enrollments = batch_enrollment_data.records.clone();

        // Extract unique student_ids from enrollment records
        let batch_student_ids: Vec<Uuid> = batch_enrollment_data
            .records
            .iter()
            .filter_map(|e| {
                e.get("student_id")
                    .and_then(|id| id.as_str())
                    .and_then(|id_str| uuid::Uuid::parse_str(id_str).ok())
            })
            .collect::<std::collections::HashSet<_>>()
            .into_iter()
            .collect();

        // Fetch enrolled student profiles (role-aware: students don't see classmates)
        let batch_enrolled_students = match user_role {
            "student" => Vec::new(),
            _ => {
                if batch_student_ids.is_empty() {
                    Vec::new()
                } else {
                    self.manifest_repo
                        .get_users_paginated(batch_student_ids, 10000)
                        .await?
                        .records
                }
            }
        };

        tracing::debug!("BATCH REQUEST: enrollments={}, enrolled_students={}",
            batch_enrollments.len(), batch_enrolled_students.len());

        // Fetch entity data (same as current logic)
        tracing::debug!("Fetching assessments for batch");
        let assessments = self
            .manifest_repo
            .get_assessments_paginated(batch_assessment_ids.clone(), 10000)
            .await?
            .records;
        tracing::debug!("Fetched {} assessments", assessments.len());

        tracing::debug!("Fetching questions for batch");
        let questions = if question_ids.is_empty() {
            tracing::debug!("No questions to fetch (question_ids is empty)");
            Vec::new()
        } else {
            self.manifest_repo
                .get_questions_paginated(question_ids.clone(), 10000)
                .await?
                .records
        };
        tracing::debug!("Fetched {} questions total for {} question_ids", questions.len(), question_ids.len());

        // Log questions per assessment
        let mut questions_by_assessment: HashMap<String, Vec<&Value>> = HashMap::new();
        for q in &questions {
            if let Some(ass_id) = q.get("assessment_id").and_then(|v| v.as_str()) {
                questions_by_assessment.entry(ass_id.to_string()).or_insert_with(Vec::new).push(q);
            }
        }
        for assessment in &assessments {
            let ass_id = assessment.get("id").and_then(|v| v.as_str()).unwrap_or("unknown");
            let ass_title = assessment.get("title").and_then(|v| v.as_str()).unwrap_or("unknown");
            let q_count = questions_by_assessment.get(ass_id).map(|v| v.len()).unwrap_or(0);
            tracing::debug!("Assessment '{}' ({}): {} questions", ass_title, ass_id, q_count);
        }

        tracing::debug!("Fetching assignments for batch");
        let assignments = self
            .manifest_repo
            .get_assignments_paginated(batch_assignment_ids.clone(), 10000)
            .await?
            .records;
        tracing::debug!("Fetched {} assignments", assignments.len());

        // Role-aware assessment submissions
        let assessment_submission_ids: Vec<Uuid> = manifest.assessment_submissions.iter().map(|e| e.id).collect();
        tracing::debug!("Fetching {} assessment submissions", assessment_submission_ids.len());
        let assessment_submissions = if assessment_submission_ids.is_empty() {
            Vec::new()
        } else {
            match user_role {
                "student" => {
                    self.manifest_repo
                        .get_student_submissions_for_assessments(user_id, batch_assessment_ids.clone(), 10000)
                        .await?
                        .records
                }
                _ => {
                    self.get_all_assessment_submissions_for_assessments(&batch_assessment_ids, 10000)
                        .await?
                }
            }
        };
        tracing::debug!("Fetched {} assessment submissions", assessment_submissions.len());

        // Role-aware assignment submissions
        let assignment_submission_ids: Vec<Uuid> = manifest.assignment_submissions.iter().map(|e| e.id).collect();
        tracing::debug!("Fetching {} assignment submissions", assignment_submission_ids.len());
        let assignment_submissions = if assignment_submission_ids.is_empty() {
            Vec::new()
        } else {
            match user_role {
                "student" => {
                    self.manifest_repo
                        .get_student_assignment_submissions_for_assignments(user_id, batch_assignment_ids.clone(), 10000)
                        .await?
                        .records
                }
                _ => {
                    self.get_all_assignment_submissions_for_assignments(&batch_assignment_ids, 10000)
                        .await?
                }
            }
        };
        tracing::debug!("Fetched {} assignment submissions", assignment_submissions.len());

        tracing::debug!("Fetching learning materials for batch");
        let learning_materials = self
            .manifest_repo
            .get_materials_paginated(batch_material_ids, 10000)
            .await?
            .records;
        tracing::debug!("Fetched {} learning materials", learning_materials.len());

        // Enrich questions and submissions
        tracing::debug!("Enriching {} questions", questions.len());
        let enriched_questions = self.enrich_questions(questions, user_role).await?;

        tracing::debug!("Enriching {} assessment submissions", assessment_submissions.len());
        let enriched_assessment_submissions = self.enrich_assessment_submissions(assessment_submissions).await?;

        // Fetch material_files
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

        // Fetch submission_files
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

        // Compute assessment statistics (teacher only)
        let assessment_statistics = match user_role {
            "student" => {
                tracing::debug!("User is student - skipping assessment statistics computation");
                vec![]
            }
            _ => {
                tracing::debug!("User is {} - computing assessment statistics from {} assessments and {} submissions",
                    user_role, assessments.len(), enriched_assessment_submissions.len());
                let stats = self.compute_assessment_statistics(&assessments, &enriched_assessment_submissions);
                tracing::debug!("Computed {} assessment statistics", stats.len());
                if !stats.is_empty() {
                    tracing::debug!("Assessment statistics: {:?}", stats);
                }
                stats
            }
        };

        // Format student results (student only)
        let student_results = match user_role {
            "student" => {
                tracing::debug!("User is student - formatting student results from {} submissions and {} assessments",
                    enriched_assessment_submissions.len(), assessments.len());
                let results = self.format_student_results(&enriched_assessment_submissions, &assessments);
                tracing::debug!("Formatted {} student results", results.len());
                if !results.is_empty() {
                    tracing::debug!("Student results: {:?}", results);
                }
                results
            }
            _ => {
                tracing::debug!("User is {} - skipping student results formatting (teacher/admin only)", user_role);
                vec![]
            }
        };

        let now = Utc::now();
        let sync_token = now.to_rfc3339();
        let server_time = now.to_rfc3339();

        tracing::info!(
            "Full sync completed successfully for user_id={} (batch). Assessments: {}, Assignments: {}, Materials: {}, Assessment Statistics: {}, Student Results: {}",
            user_id,
            assessments.len(),
            assignments.len(),
            learning_materials.len(),
            assessment_statistics.len(),
            student_results.len()
        );


        tracing::debug!(
            "Full sync response for user_id={}: {} assessments, {} questions, {} submissions",
            user_id,
            assessments.len(),
            enriched_questions.len(),
            enriched_assessment_submissions.len()
        );

        Ok(FullSyncResponse {
            sync_token,
            server_time,
            user: None, // Not returned in batch requests (already returned in base)
            classes: vec![], // Not returned in batch requests
            enrollments: batch_enrollments, // Batch classes' enrollments for full offline support
            enrolled_students: batch_enrolled_students, // Batch classes' students for full offline support
            assessments,
            questions: enriched_questions,
            assessment_submissions: enriched_assessment_submissions,
            assignments,
            assignment_submissions,
            learning_materials,
            material_files,
            submission_files,
            assessment_statistics,
            student_results,
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

    /// Compute assessment statistics from enriched submissions (teacher only)
    fn compute_assessment_statistics(
        &self,
        assessments: &[Value],
        enriched_submissions: &[Value],
    ) -> Vec<Value> {
        let mut stats = Vec::new();

        // Build submission map: assessment_id -> submissions
        let mut submissions_by_assessment: HashMap<String, Vec<&Value>> = HashMap::new();
        for sub in enriched_submissions {
            if let Some(ass_id) = sub.get("assessment_id").and_then(|v| v.as_str()) {
                submissions_by_assessment.entry(ass_id.to_string()).or_insert_with(Vec::new).push(sub);
            }
        }

        for assessment in assessments {
            let assessment_id = assessment.get("id").and_then(|v| v.as_str()).unwrap_or("");
            let title = assessment.get("title").and_then(|v| v.as_str()).unwrap_or("");
            let total_points = assessment.get("total_points").and_then(|v| v.as_i64()).unwrap_or(0) as f64;

            let empty_vec = vec![];
            let submissions = submissions_by_assessment.get(assessment_id).unwrap_or(&empty_vec);

            // Filter submitted submissions
            let submitted: Vec<&Value> = submissions.iter()
                .filter(|s| s.get("is_submitted").and_then(|v| v.as_u64()).unwrap_or(0) == 1)
                .copied()
                .collect();

            if submitted.is_empty() {
                continue; // Skip if no submitted submissions
            }

            // Extract scores
            let mut scores: Vec<f64> = submitted.iter()
                .filter_map(|s| {
                    s.get("final_score")
                        .and_then(|v| v.as_f64())
                        .or_else(|| s.get("auto_score").and_then(|v| v.as_f64()))
                })
                .collect();
            scores.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));

            // Compute statistics
            let mean = scores.iter().sum::<f64>() / scores.len() as f64;
            let median = if scores.len() % 2 == 0 {
                (scores[scores.len() / 2 - 1] + scores[scores.len() / 2]) / 2.0
            } else {
                scores[scores.len() / 2]
            };
            let highest = scores.last().copied().unwrap_or(0.0);
            let lowest = scores.first().copied().unwrap_or(0.0);

            // Score distribution
            let mut distribution = vec![
                ("0-25%", 0),
                ("26-50%", 0),
                ("51-75%", 0),
                ("76-100%", 0),
            ];
            for score in &scores {
                let percentage = if total_points > 0.0 { (score / total_points) * 100.0 } else { 0.0 };
                match percentage {
                    p if p <= 25.0 => distribution[0].1 += 1,
                    p if p <= 50.0 => distribution[1].1 += 1,
                    p if p <= 75.0 => distribution[2].1 += 1,
                    _ => distribution[3].1 += 1,
                }
            }

            stats.push(json!({
                "assessment_id": assessment_id,
                "title": title,
                "total_points": total_points as i64,
                "submission_count": submitted.len(),
                "class_statistics": {
                    "mean": mean,
                    "median": median,
                    "highest": highest,
                    "lowest": lowest,
                    "score_distribution": distribution.iter().map(|(range, count)| {
                        json!({"range": range, "count": count})
                    }).collect::<Vec<_>>()
                },
                "question_statistics": []
            }));
        }

        stats
    }

    /// Format student results from enriched submissions (student only)
    fn format_student_results(
        &self,
        enriched_submissions: &[Value],
        assessments: &[Value],
    ) -> Vec<Value> {
        let mut results = Vec::new();

        // Build assessment map: assessment_id -> total_points
        let mut assessment_map: HashMap<String, i64> = HashMap::new();
        for assessment in assessments {
            if let Some(ass_id) = assessment.get("id").and_then(|v| v.as_str()) {
                let total_points = assessment.get("total_points").and_then(|v| v.as_i64()).unwrap_or(0);
                assessment_map.insert(ass_id.to_string(), total_points);
            }
        }

        for submission in enriched_submissions {
            if submission.get("is_submitted").and_then(|v| v.as_u64()).unwrap_or(0) != 1 {
                continue; // Skip unsubmitted
            }

            let submission_id = submission.get("id").and_then(|v| v.as_str()).unwrap_or("");
            let assessment_id = submission.get("assessment_id").and_then(|v| v.as_str()).unwrap_or("");
            let total_points = assessment_map.get(assessment_id).copied().unwrap_or(0);
            let auto_score = submission.get("auto_score").and_then(|v| v.as_f64()).unwrap_or(0.0);
            let final_score = submission.get("final_score").and_then(|v| v.as_f64()).unwrap_or(auto_score);
            let submitted_at = submission.get("submitted_at").and_then(|v| v.as_str()).unwrap_or("");

            // Transform answers: convert selected_choices from [object] to [string]
            let mut answers_json = Vec::new();
            if let Some(answers) = submission.get("answers").and_then(|v| v.as_array()) {
                for answer in answers {
                    let mut ans_obj = answer.clone();

                    // Extract choice_text from selected_choices objects
                    if let Some(choices) = ans_obj.get("selected_choices").and_then(|v| v.as_array()) {
                        let choice_texts: Vec<Value> = choices.iter()
                            .filter_map(|c| c.get("choice_text").cloned())
                            .collect();
                        ans_obj["selected_choices"] = json!(choice_texts);
                    }

                    // Ensure correct_answers is an empty array if not present
                    if !ans_obj.get("correct_answers").is_some() {
                        ans_obj["correct_answers"] = json!([]);
                    }

                    answers_json.push(ans_obj);
                }
            }

            results.push(json!({
                "submission_id": submission_id,
                "auto_score": auto_score,
                "final_score": final_score,
                "total_points": total_points,
                "submitted_at": submitted_at,
                "answers": answers_json
            }));
        }

        results
    }
}
