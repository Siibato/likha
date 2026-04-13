use chrono::Utc;
use serde_json::Value;
use std::collections::{HashMap, HashSet};
use uuid::Uuid;

use crate::utils::AppResult;
use crate::services::sync_common::enrich_questions;

use super::sync_full_service::{FullSyncRequest, FullSyncResponse};
use super::enrich_submissions::enrich_assessment_submissions;
use super::statistics::{compute_assessment_statistics, format_student_results};

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
                grade_configs: vec![],
                grade_items: vec![],
                grade_scores: vec![],
                period_grades: vec![],
                table_of_specifications: vec![],
                tos_competencies: vec![],
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
                grade_configs: vec![],
                grade_items: vec![],
                grade_scores: vec![],
                period_grades: vec![],
                table_of_specifications: vec![],
                tos_competencies: vec![],
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
        let enriched_questions = enrich_questions(&self.db, questions, user_role).await?;

        tracing::debug!("Enriching {} assessment submissions", assessment_submissions.len());
        let enriched_assessment_submissions = enrich_assessment_submissions(&self.db, assessment_submissions).await?;

        // Fetch material_files
        let material_ids: Vec<Uuid> = learning_materials
            .iter()
            .filter_map(|m| m.get("id").and_then(|id| id.as_str()).and_then(|s| Uuid::parse_str(s).ok()))
            .collect();
        tracing::debug!("Fetching material files for {} materials", material_ids.len());
        let material_files = if material_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo.get_material_files_for_materials(material_ids).await?
        };
        tracing::debug!("Fetched {} material files", material_files.len());

        // Fetch submission_files (for assignment submissions — FK points to assignment_submissions.id, not assessments)
        let submission_ids: Vec<Uuid> = assignment_submissions
            .iter()
            .filter_map(|s| s.get("id").and_then(|id| id.as_str()).and_then(|s| Uuid::parse_str(s).ok()))
            .collect();
        tracing::debug!("Fetching submission files for {} submissions", submission_ids.len());
        let submission_files = if submission_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo.get_submission_files_for_submissions(submission_ids).await?
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
                let stats = compute_assessment_statistics(&assessments, &enriched_assessment_submissions);
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
                let results = format_student_results(&enriched_assessment_submissions, &assessments);
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

        // Fetch grading data for batch classes
        tracing::debug!("Fetching grading data for batch");
        let grade_configs = self.manifest_repo
            .get_grade_configs_for_classes(batch_class_ids.clone())
            .await?;
        let grade_items_data = self.manifest_repo
            .get_grade_items_for_classes(batch_class_ids.clone())
            .await?;

        // Get grade_item IDs for score fetching
        let grade_item_ids: Vec<Uuid> = grade_items_data
            .iter()
            .filter_map(|gi| gi.get("id").and_then(|id| id.as_str()).and_then(|s| Uuid::parse_str(s).ok()))
            .collect();

        // Role-aware grade scores
        let grade_scores_data = if grade_item_ids.is_empty() {
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

        // Role-aware quarterly grades
        let quarterly_grades_data = match user_role {
            "student" => {
                self.manifest_repo
                    .get_student_quarterly_grades(user_id, batch_class_ids.clone())
                    .await?
            }
            _ => {
                self.manifest_repo
                    .get_all_quarterly_grades(batch_class_ids.clone())
                    .await?
            }
        };

        tracing::debug!("Fetched grading data: configs={}, items={}, scores={}, quarterly={}",
            grade_configs.len(), grade_items_data.len(), grade_scores_data.len(), quarterly_grades_data.len());

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
            grade_configs,
            grade_items: grade_items_data,
            grade_scores: grade_scores_data,
            period_grades: quarterly_grades_data,
            table_of_specifications: vec![], // TOS data fetched when available
            tos_competencies: vec![],
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
