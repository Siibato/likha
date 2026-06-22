use chrono::Utc;
use serde_json::Value;
use std::collections::{HashMap, HashSet};
use uuid::Uuid;

use sea_orm::{ColumnTrait, EntityTrait, QueryFilter};
use crate::utils::AppResult;
use crate::modules::sync::helpers::enrich_questions;
use crate::modules::sync::sync_scope::SyncScope;
use crate::modules::setup::repository::SetupRepository;
use crate::modules::setup::schema::SchoolDetailsResponse;

use super::sync_full_service::{FullSyncRequest, FullSyncResponse};
use super::enrich_submissions::enrich_assessment_submissions;
use super::statistics::format_student_results;

impl super::SyncFullService {
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

        let scope = SyncScope::for_role(user_role);

        let needs_entity_batches = scope.include_assessments
            || scope.include_assignments
            || scope.include_learning_materials
            || scope.include_grade_data
            || scope.include_tos
            || scope.include_submissions;

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

            // Compute student count per class from enrollments (no additional queries needed)
            let mut student_count_by_class: std::collections::HashMap<String, usize> = std::collections::HashMap::new();
            for enrollment in &enrollments {
                if let Some(serde_json::Value::String(class_id)) = enrollment.get("class_id") {
                    *student_count_by_class.entry(class_id.clone()).or_insert(0) += 1;
                }
            }

            // Enrich classes with computed student_count
            let mut classes = classes;
            for cls in &mut classes {
                if let Some(serde_json::Value::String(class_id)) = cls.get("id") {
                    if let Some(&count) = student_count_by_class.get(class_id) {
                        cls["student_count"] = serde_json::json!(count);
                    }
                }
            }

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

            let total_classes = classes.len();

            let now = Utc::now();
            let sync_token = now.to_rfc3339();
            let server_time = now.to_rfc3339();

            let activity_logs = if scope.include_activity_logs {
                let log_ids: Vec<Uuid> = manifest.activity_logs.iter().map(|e| e.id).collect();
                if log_ids.is_empty() {
                    Vec::new()
                } else {
                    self.manifest_repo
                        .get_activity_logs_paginated(log_ids, 10000)
                        .await?
                        .records
                }
            } else {
                Vec::new()
            };

            // Fetch school details for all authenticated users
            let school_details = {
                let setup_repo = SetupRepository::new(self.db.clone());
                match setup_repo.get_settings().await {
                    Ok(row) => Some(SchoolDetailsResponse {
                        school_code: row.school_code,
                        school_name: row.school_name,
                        school_region: row.school_region,
                        school_division: row.school_division,
                        school_year: row.school_year,
                        school_district: row.school_district,
                        school_head_name: row.school_head_name,
                        school_head_position: row.school_head_position,
                    }),
                    Err(e) => {
                        tracing::warn!("Failed to fetch school details for sync: {}", e);
                        None
                    }
                }
            };

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
                grade_configs: vec![],
                grade_items: vec![],
                grade_scores: vec![],
                term_grades: vec![],
                table_of_specifications: vec![],
                tos_competencies: vec![],
                activity_logs,
                sync_plan: Some(super::sync_full_service::SyncPlan {
                    needs_entity_batches,
                    total_classes,
                }),
                school_details,
                learner_details: vec![],
                teacher_details: vec![],
                attendance_records: vec![],
                core_values_records: vec![],
                student_school_history: vec![],
                previous_school_subjects: vec![],
                previous_school_term_grades: vec![],
                previous_school_attendance: vec![],
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
        let _batch_class_id_set: std::collections::HashSet<Uuid> = batch_class_ids.iter().cloned().collect();

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
                grade_configs: vec![],
                grade_items: vec![],
                grade_scores: vec![],
                term_grades: vec![],
                table_of_specifications: vec![],
                tos_competencies: vec![],
                activity_logs: vec![],
                sync_plan: None,
                school_details: None,
                learner_details: vec![],
                teacher_details: vec![],
                attendance_records: vec![],
                core_values_records: vec![],
                student_school_history: vec![],
                previous_school_subjects: vec![],
                previous_school_term_grades: vec![],
                previous_school_attendance: vec![],
            });
        }

        // NOTE: We now fetch assessments/assignments/materials directly by class_id
        // instead of gathering manifest IDs and filtering in Rust.

        // NOTE: enrollments and enrolled_students are already sent in the base request.
        // Skip redundant re-fetching in batch requests to reduce payload and DB load.
        tracing::debug!("BATCH REQUEST: skipping redundant enrollments/enrolled_students (already in base response)");

        let mut assessments: Vec<Value> = Vec::new();
        let mut actual_batch_assessment_ids: Vec<Uuid> = Vec::new();
        let mut enriched_questions: Vec<Value> = Vec::new();
        let mut enriched_assessment_submissions: Vec<Value> = Vec::new();
        let mut assignments: Vec<Value> = Vec::new();
        let mut actual_batch_assignment_ids: Vec<Uuid> = Vec::new();
        let mut assignment_submissions: Vec<Value> = Vec::new();
        let mut learning_materials: Vec<Value> = Vec::new();
        let mut material_files: Vec<Value> = Vec::new();
        let mut submission_files: Vec<Value> = Vec::new();
        let mut assessment_statistics: Vec<Value> = Vec::new();
        let mut student_results: Vec<Value> = Vec::new();
        let mut grade_configs: Vec<Value> = Vec::new();
        let mut grade_items_data: Vec<Value> = Vec::new();
        let mut grade_scores_data: Vec<Value> = Vec::new();
        let mut term_grades_data: Vec<Value> = Vec::new();
        let mut table_of_specifications: Vec<Value> = Vec::new();
        let mut tos_competencies: Vec<Value> = Vec::new();

        if scope.include_assessments {
            tracing::debug!("Fetching assessments for batch");
            assessments = self
                .manifest_repo
                .get_assessments_for_classes(batch_class_ids.clone(), 10000)
                .await?
                .records;
            actual_batch_assessment_ids = assessments
                .iter()
                .filter_map(|a| a.get("id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()))
                .collect();
            tracing::debug!("Fetched {} assessments", assessments.len());
        }

        let questions: Vec<Value>;
        if scope.include_questions {
            let question_ids: Vec<Uuid> = if actual_batch_assessment_ids.is_empty() {
                Vec::new()
            } else {
                self.manifest_repo
                    .get_questions_manifest(actual_batch_assessment_ids.clone())
                    .await?
                    .iter()
                    .map(|e| e.id)
                    .collect()
            };
            tracing::debug!("BATCH REQUEST: Found {} question_ids in manifest for {} assessments",
                question_ids.len(), actual_batch_assessment_ids.len());

            tracing::debug!("Fetching questions for batch");
            questions = if question_ids.is_empty() {
                tracing::debug!("No questions to fetch (question_ids is empty)");
                Vec::new()
            } else {
                self.manifest_repo
                    .get_questions_paginated(question_ids.clone(), 10000)
                    .await?
                    .records
            };
            tracing::debug!("Fetched {} questions total for {} question_ids", questions.len(), question_ids.len());

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

            tracing::debug!("Enriching {} questions", questions.len());
            enriched_questions = enrich_questions(&self.db, questions, user_role).await?;
        }

        if scope.include_assignments {
            tracing::debug!("Fetching assignments for batch");
            assignments = self
                .manifest_repo
                .get_assignments_for_classes(batch_class_ids.clone(), 10000)
                .await?
                .records;
            actual_batch_assignment_ids = assignments
                .iter()
                .filter_map(|a| a.get("id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()))
                .collect();
            tracing::debug!("Fetched {} assignments", assignments.len());
        }

        let assessment_submissions: Vec<Value>;
        if scope.include_submissions {
            let assessment_submission_ids: Vec<Uuid> = manifest.assessment_submissions.iter().map(|e| e.id).collect();
            tracing::debug!("Fetching {} assessment submissions", assessment_submission_ids.len());
            assessment_submissions = if assessment_submission_ids.is_empty() {
                Vec::new()
            } else {
                match user_role {
                    "student" => {
                        self.manifest_repo
                            .get_student_submissions_for_assessments(user_id, actual_batch_assessment_ids.clone(), 10000)
                            .await?
                            .records
                    }
                    _ => {
                        self.get_all_assessment_submissions_for_assessments(&actual_batch_assessment_ids, 10000)
                            .await?
                    }
                }
            };
            tracing::debug!("Fetched {} assessment submissions", assessment_submissions.len());

            let assignment_submission_ids: Vec<Uuid> = manifest.assignment_submissions.iter().map(|e| e.id).collect();
            tracing::debug!("Fetching {} assignment submissions", assignment_submission_ids.len());
            assignment_submissions = if assignment_submission_ids.is_empty() {
                Vec::new()
            } else {
                match user_role {
                    "student" => {
                        self.manifest_repo
                            .get_student_assignment_submissions_for_assignments(user_id, actual_batch_assignment_ids.clone(), 10000)
                            .await?
                            .records
                    }
                    _ => {
                        self.get_all_assignment_submissions_for_assignments(&actual_batch_assignment_ids, 10000)
                            .await?
                    }
                }
            };
            tracing::debug!("Fetched {} assignment submissions", assignment_submissions.len());

            tracing::debug!("Enriching {} assessment submissions", assessment_submissions.len());
            enriched_assessment_submissions = enrich_assessment_submissions(&self.db, assessment_submissions).await?;
        }

        if scope.include_learning_materials {
            tracing::debug!("Fetching learning materials for batch");
            learning_materials = self
                .manifest_repo
                .get_materials_for_classes(batch_class_ids.clone(), 10000)
                .await?
                .records;
            tracing::debug!("Fetched {} learning materials", learning_materials.len());
        }

        if scope.include_files {
            let material_ids: Vec<Uuid> = learning_materials
                .iter()
                .filter_map(|m| m.get("id").and_then(|id| id.as_str()).and_then(|s| Uuid::parse_str(s).ok()))
                .collect();
            tracing::debug!("Fetching material files for {} materials", material_ids.len());
            material_files = if material_ids.is_empty() {
                Vec::new()
            } else {
                self.manifest_repo.get_material_files_for_materials(material_ids).await?
            };
            tracing::debug!("Fetched {} material files", material_files.len());

            let submission_ids: Vec<Uuid> = assignment_submissions
                .iter()
                .filter_map(|s| s.get("id").and_then(|id| id.as_str()).and_then(|s| Uuid::parse_str(s).ok()))
                .collect();
            tracing::debug!("Fetching submission files for {} submissions", submission_ids.len());
            submission_files = if submission_ids.is_empty() {
                Vec::new()
            } else {
                self.manifest_repo.get_submission_files_for_submissions(submission_ids).await?
            };
            tracing::debug!("Fetched {} submission files", submission_files.len());
        }

        if scope.include_statistics {
            // Server-side statistics are skipped for teachers/admins;
            // the client computes them on-demand from raw assessment + submission data.
            assessment_statistics = match user_role {
                "student" => {
                    tracing::debug!("User is student - skipping assessment statistics computation");
                    vec![]
                }
                _ => {
                    tracing::debug!("User is {} - skipping server-side statistics (computed client-side)", user_role);
                    vec![]
                }
            };

            student_results = match user_role {
                "student" => {
                    tracing::debug!("User is student - formatting student results from {} submissions and {} assessments",
                        enriched_assessment_submissions.len(), assessments.len());
                    let results = format_student_results(&enriched_assessment_submissions, &assessments);
                    tracing::debug!("Formatted {} student results", results.len());
                    if !results.is_empty() {
                        tracing::debug!("Student results: {:?}", results);
                    }
                    results
                }
                _ => {
                    tracing::debug!("User is {} - skipping student results formatting (computed client-side)", user_role);
                    vec![]
                }
            };
        }

        if scope.include_grade_data {
            tracing::debug!("Fetching grading data for batch");
            let (grade_configs_result, grade_items_result) = tokio::try_join!(
                self.manifest_repo.get_grade_configs_for_classes(batch_class_ids.clone()),
                self.manifest_repo.get_grade_items_for_classes(batch_class_ids.clone()),
            )?;
            grade_configs = grade_configs_result;
            grade_items_data = grade_items_result;

            let grade_item_ids: Vec<Uuid> = grade_items_data
                .iter()
                .filter_map(|gi| gi.get("id").and_then(|id| id.as_str()).and_then(|s| Uuid::parse_str(s).ok()))
                .collect();

            grade_scores_data = if grade_item_ids.is_empty() {
                Vec::new()
            } else {
                match user_role {
                    "student" => {
                        self.manifest_repo
                            .get_student_grade_scores(user_id, grade_item_ids)
                            .await?
                    }
                    _ => {
                        self.manifest_repo
                            .get_all_grade_scores(grade_item_ids)
                            .await?
                    }
                }
            };

            term_grades_data = match user_role {
                "student" => {
                    self.manifest_repo
                        .get_student_term_grades(user_id, batch_class_ids.clone())
                        .await?
                }
                _ => {
                    self.manifest_repo
                        .get_all_term_grades(batch_class_ids.clone())
                        .await?
                }
            };

            tracing::debug!("Fetched grading data: configs={}, items={}, scores={}, term_grades={}",
                grade_configs.len(), grade_items_data.len(), grade_scores_data.len(), term_grades_data.len());
        }

        if scope.include_tos {
            table_of_specifications = self.manifest_repo
                .get_table_of_specifications_for_classes(batch_class_ids.clone())
                .await?;

            let tos_ids: Vec<Uuid> = table_of_specifications
                .iter()
                .filter_map(|tos| tos.get("id").and_then(|id| id.as_str()).and_then(|s| Uuid::parse_str(s).ok()))
                .collect();

            tos_competencies = if tos_ids.is_empty() {
                Vec::new()
            } else {
                self.manifest_repo
                    .get_tos_competencies_for_tos_ids(tos_ids)
                    .await?
            };

            tracing::debug!("Fetched TOS data: table_of_specifications={}, tos_competencies={}",
                table_of_specifications.len(), tos_competencies.len());
        }

        // NOTE: activity_logs are already sent in the base request.
        // Skip redundant re-fetching in batch requests.
        tracing::debug!("BATCH REQUEST: skipping redundant activity_logs (already in base response)");

        // Fetch student records if scoped
        let mut learner_details: Vec<Value> = Vec::new();
        let mut teacher_details: Vec<Value> = Vec::new();
        let mut attendance_records: Vec<Value> = Vec::new();
        let mut core_values_records: Vec<Value> = Vec::new();
        let mut student_school_history: Vec<Value> = Vec::new();
        let mut previous_school_subjects: Vec<Value> = Vec::new();
        let mut previous_school_term_grades: Vec<Value> = Vec::new();
        let mut previous_school_attendance: Vec<Value> = Vec::new();

        if scope.include_student_records {
            tracing::debug!("Fetching student records for batch");

            // Derive student_ids from class_participants for the batch's classes
            let participants = ::entity::class_participants::Entity::find()
                .filter(::entity::class_participants::Column::ClassId.is_in(batch_class_ids.clone()))
                .filter(::entity::class_participants::Column::RemovedAt.is_null())
                .all(&self.db)
                .await
                .map_err(|e| crate::utils::AppError::InternalServerError(format!("Database error: {}", e)))?;

            let student_ids: Vec<Uuid> = participants
                .iter()
                .map(|p| p.user_id)
                .collect::<HashSet<_>>()
                .into_iter()
                .collect();

            learner_details = self
                .manifest_repo
                .get_learner_details_for_students(student_ids.clone(), 10000)
                .await?
                .records;

            // Derive teacher_ids from class_participants by looking up user roles
            let participant_user_ids: Vec<Uuid> = participants
                .iter()
                .map(|p| p.user_id)
                .collect::<HashSet<_>>()
                .into_iter()
                .collect();

            let teacher_ids: Vec<Uuid> = if participant_user_ids.is_empty() {
                Vec::new()
            } else {
                ::entity::users::Entity::find()
                    .filter(::entity::users::Column::Id.is_in(participant_user_ids))
                    .filter(::entity::users::Column::Role.eq("teacher"))
                    .filter(::entity::users::Column::DeletedAt.is_null())
                    .all(&self.db)
                    .await
                    .map_err(|e| crate::utils::AppError::InternalServerError(format!("Database error: {}", e)))?
                    .into_iter()
                    .map(|u| u.id)
                    .collect()
            };

            // For admin, also fetch all users with role=teacher (not just class participants)
            let teacher_ids = if user_role == "admin" {
                ::entity::users::Entity::find()
                    .filter(::entity::users::Column::Role.eq("teacher"))
                    .filter(::entity::users::Column::DeletedAt.is_null())
                    .all(&self.db)
                    .await
                    .map_err(|e| crate::utils::AppError::InternalServerError(format!("Database error: {}", e)))?
                    .into_iter()
                    .map(|u| u.id)
                    .collect::<HashSet<_>>()
                    .into_iter()
                    .collect()
            } else {
                teacher_ids
            };

            teacher_details = self
                .manifest_repo
                .get_teacher_details_for_teachers(teacher_ids, 10000)
                .await?
                .records;

            attendance_records = self
                .manifest_repo
                .get_attendance_for_classes(batch_class_ids.clone(), 10000)
                .await?
                .records;

            core_values_records = self
                .manifest_repo
                .get_core_values_for_classes(batch_class_ids.clone(), 10000)
                .await?
                .records;

            student_school_history = self
                .manifest_repo
                .get_school_history_for_students(student_ids.clone(), 10000)
                .await?
                .records;

            previous_school_subjects = self
                .manifest_repo
                .get_previous_subjects_for_students(student_ids.clone(), 10000)
                .await?
                .records;

            // Fetch term grades for those subjects
            let subject_ids: Vec<Uuid> = previous_school_subjects.iter()
                .filter_map(|s| s.get("id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()))
                .collect();
            previous_school_term_grades = if subject_ids.is_empty() {
                Vec::new()
            } else {
                self.manifest_repo
                    .get_previous_school_term_grades_since(subject_ids, chrono::NaiveDateTime::MIN)
                    .await?
            };

            previous_school_attendance = self
                .manifest_repo
                .get_previous_attendance_for_students(student_ids, 10000)
                .await?
                .records;

            tracing::debug!(
                "Fetched student records: learner_details={}, attendance={}, core_values={}, school_history={}, prev_subjects={}, prev_term_grades={}, prev_attendance={}",
                learner_details.len(),
                attendance_records.len(),
                core_values_records.len(),
                student_school_history.len(),
                previous_school_subjects.len(),
                previous_school_term_grades.len(),
                previous_school_attendance.len()
            );
        }

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
            user: None,
            classes: vec![],
            enrollments: vec![],
            enrolled_students: vec![],
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
            grade_configs,
            grade_items: grade_items_data,
            grade_scores: grade_scores_data,
            term_grades: term_grades_data,
            table_of_specifications,
            tos_competencies,
            activity_logs: vec![],
            sync_plan: None,
            school_details: None,
            learner_details,
            teacher_details,
            attendance_records,
            core_values_records,
            student_school_history,
            previous_school_subjects,
            previous_school_term_grades,
            previous_school_attendance,
        })
    }

    pub(super) async fn get_all_assessment_submissions_for_assessments(
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

    pub(super) async fn get_all_assignment_submissions_for_assignments(
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
}
