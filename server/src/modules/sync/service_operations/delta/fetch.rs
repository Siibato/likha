use chrono::{Duration, NaiveDateTime, Utc};
use uuid::Uuid;

use sea_orm::{ColumnTrait, EntityTrait, QueryFilter};
use crate::utils::{AppError, AppResult};
use crate::modules::sync::helpers::enrich_questions;
use crate::modules::sync::sync_scope::SyncScope;

use super::sync_delta_service::{DeltaRequest, DeltaResponse, DeltaPayload};
use super::separate_deltas::separate_deltas;

impl super::SyncDeltaService {
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

        let scope = SyncScope::for_role(user_role);

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

        let mut assessments: Vec<serde_json::Value> = Vec::new();
        let mut questions: Vec<serde_json::Value> = Vec::new();
        let mut assessment_submissions: Vec<serde_json::Value> = Vec::new();
        let mut assignments: Vec<serde_json::Value> = Vec::new();
        let mut assignment_submissions: Vec<serde_json::Value> = Vec::new();
        let mut learning_materials: Vec<serde_json::Value> = Vec::new();
        let mut grade_configs_raw: Vec<serde_json::Value> = Vec::new();
        let mut grade_items_raw: Vec<serde_json::Value> = Vec::new();
        let mut grade_scores_raw: Vec<serde_json::Value> = Vec::new();
        let mut term_grades_raw: Vec<serde_json::Value> = Vec::new();
        let mut tos_raw: Vec<serde_json::Value> = Vec::new();
        let mut tos_competencies_raw: Vec<serde_json::Value> = Vec::new();
        let mut activity_logs_raw: Vec<serde_json::Value> = Vec::new();

        if scope.include_assessments {
            tracing::debug!("Fetching assessment deltas since {}", last_sync_at);
            assessments = self
                .manifest_repo
                .get_assessments_since(
                    manifest.assessments.iter().map(|e| e.id).collect(),
                    last_sync_at,
                )
                .await?;
            tracing::debug!("Got {} assessment deltas", assessments.len());
        }

        if scope.include_questions {
            let question_ids: Vec<Uuid> = manifest.assessment_questions.iter().map(|e| e.id).collect();
            tracing::debug!("Fetching {} question deltas since {}", question_ids.len(), last_sync_at);
            questions = if question_ids.is_empty() {
                Vec::new()
            } else {
                let raw_questions = self.manifest_repo
                    .get_questions_since(question_ids, last_sync_at)
                    .await?;
                enrich_questions(&self.db, raw_questions, user_role).await?
            };
            tracing::debug!("Got {} question deltas", questions.len());
        }

        if scope.include_submissions {
            let assessment_submission_ids: Vec<Uuid> =
                manifest.assessment_submissions.iter().map(|e| e.id).collect();
            tracing::debug!("Fetching {} assessment submission deltas since {}", assessment_submission_ids.len(), last_sync_at);
            assessment_submissions = if assessment_submission_ids.is_empty() {
                Vec::new()
            } else {
                self.manifest_repo
                    .get_assessment_submissions_since(user_id, assessment_submission_ids, last_sync_at)
                    .await?
            };
            tracing::debug!("Got {} assessment submission deltas", assessment_submissions.len());
        }

        if scope.include_assignments {
            tracing::debug!("Fetching assignment deltas since {}", last_sync_at);
            assignments = self
                .manifest_repo
                .get_assignments_since(
                    manifest.assignments.iter().map(|e| e.id).collect(),
                    last_sync_at,
                )
                .await?;
            tracing::debug!("Got {} assignment deltas", assignments.len());
        }

        if scope.include_submissions {
            let assignment_submission_ids: Vec<Uuid> =
                manifest.assignment_submissions.iter().map(|e| e.id).collect();
            tracing::debug!("Fetching {} assignment submission deltas since {}", assignment_submission_ids.len(), last_sync_at);
            assignment_submissions = if assignment_submission_ids.is_empty() {
                Vec::new()
            } else {
                self.manifest_repo
                    .get_assignment_submissions_since(user_id, assignment_submission_ids, last_sync_at)
                    .await?
            };
            tracing::debug!("Got {} assignment submission deltas", assignment_submissions.len());
        }

        if scope.include_learning_materials {
            tracing::debug!("Fetching learning material deltas since {}", last_sync_at);
            learning_materials = self
                .manifest_repo
                .get_materials_since(
                    manifest.learning_materials.iter().map(|e| e.id).collect(),
                    last_sync_at,
                )
                .await?;
            tracing::debug!("Got {} learning material deltas", learning_materials.len());
        }

        if scope.include_grade_data {
            let class_ids: Vec<Uuid> = manifest.classes.iter().map(|e| e.id).collect();
            grade_configs_raw = self.manifest_repo
                .get_grade_configs_since(class_ids.clone(), last_sync_at)
                .await?;
            grade_items_raw = self.manifest_repo
                .get_grade_items_since(class_ids.clone(), last_sync_at)
                .await?;

            let all_grade_item_ids: Vec<Uuid> = self.manifest_repo
                .get_grade_item_ids_for_classes(class_ids.clone())
                .await?;

            grade_scores_raw = if all_grade_item_ids.is_empty() {
                Vec::new()
            } else {
                match user_role {
                    "student" => self.manifest_repo
                        .get_student_grade_scores_since(user_id, all_grade_item_ids, last_sync_at)
                        .await?,
                    _ => self.manifest_repo
                        .get_all_grade_scores_since(all_grade_item_ids, last_sync_at)
                        .await?,
                }
            };

            term_grades_raw = match user_role {
                "student" => self.manifest_repo
                    .get_student_term_grades_since(user_id, class_ids, last_sync_at)
                    .await?,
                _ => self.manifest_repo
                    .get_all_term_grades_since(class_ids, last_sync_at)
                    .await?,
            };
        }

        if scope.include_tos {
            tos_raw = self.manifest_repo
                .get_table_of_specifications_since(manifest.classes.iter().map(|e| e.id).collect(), last_sync_at)
                .await?;
            tos_competencies_raw = self.manifest_repo
                .get_tos_competencies_since(manifest.classes.iter().map(|e| e.id).collect(), last_sync_at)
                .await?;
        }

        if scope.include_activity_logs {
            let activity_log_ids: Vec<Uuid> = manifest.activity_logs.iter().map(|e| e.id).collect();
            tracing::debug!("Fetching {} activity log deltas since {}", activity_log_ids.len(), last_sync_at);
            activity_logs_raw = if activity_log_ids.is_empty() {
                Vec::new()
            } else {
                self.manifest_repo
                    .get_activity_logs_since(activity_log_ids, last_sync_at)
                    .await?
            };
            tracing::debug!("Got {} activity log deltas", activity_logs_raw.len());
        }

        // Fetch school settings delta (global, not role-scoped)
        tracing::debug!("Fetching school settings deltas since {}", last_sync_at);
        let school_details_raw = self
            .manifest_repo
            .get_school_details_since(last_sync_at)
            .await?;
        tracing::debug!("Got {} school settings deltas", school_details_raw.len());

        // Fetch student record deltas if scoped
        let mut learner_details_raw: Vec<serde_json::Value> = Vec::new();
        let mut attendance_records_raw: Vec<serde_json::Value> = Vec::new();
        let mut core_values_records_raw: Vec<serde_json::Value> = Vec::new();
        let mut student_school_history_raw: Vec<serde_json::Value> = Vec::new();
        let mut previous_school_subjects_raw: Vec<serde_json::Value> = Vec::new();
        let mut previous_school_attendance_raw: Vec<serde_json::Value> = Vec::new();

        if scope.include_student_records {
            let class_ids: Vec<Uuid> = manifest.classes.iter().map(|e| e.id).collect();

            // Derive student_ids from class_participants for all entitled classes
            let participants = ::entity::class_participants::Entity::find()
                .filter(::entity::class_participants::Column::ClassId.is_in(class_ids.clone()))
                .filter(::entity::class_participants::Column::RemovedAt.is_null())
                .all(&self.db)
                .await
                .map_err(|e| crate::utils::AppError::InternalServerError(format!("Database error: {}", e)))?;

            let student_ids: Vec<Uuid> = participants
                .iter()
                .map(|p| p.user_id)
                .collect::<std::collections::HashSet<_>>()
                .into_iter()
                .collect();

            learner_details_raw = self.manifest_repo
                .get_learner_details_since(student_ids.clone(), last_sync_at)
                .await?;
            attendance_records_raw = self.manifest_repo
                .get_attendance_since(class_ids.clone(), last_sync_at)
                .await?;
            core_values_records_raw = self.manifest_repo
                .get_core_values_since(class_ids.clone(), last_sync_at)
                .await?;
            student_school_history_raw = self.manifest_repo
                .get_school_history_since(student_ids.clone(), last_sync_at)
                .await?;
            previous_school_subjects_raw = self.manifest_repo
                .get_previous_subjects_since(student_ids.clone(), last_sync_at)
                .await?;
            previous_school_attendance_raw = self.manifest_repo
                .get_previous_attendance_since(student_ids, last_sync_at)
                .await?;
        }

        // Step 6: Separate updated vs deleted for each entity type
        let classes_deltas = separate_deltas(classes);
        let enrollments_deltas = separate_deltas(enrollments);
        let assessments_deltas = separate_deltas(assessments);
        let questions_deltas = separate_deltas(questions);
        let assessment_submissions_deltas = separate_deltas(assessment_submissions);
        let assignments_deltas = separate_deltas(assignments);
        let assignment_submissions_deltas = separate_deltas(assignment_submissions);
        let learning_materials_deltas = separate_deltas(learning_materials);
        let grade_configs_deltas = separate_deltas(grade_configs_raw);
        let grade_items_deltas = separate_deltas(grade_items_raw);
        let grade_scores_deltas = separate_deltas(grade_scores_raw);
        let term_grades_deltas = separate_deltas(term_grades_raw);
        let tos_deltas = separate_deltas(tos_raw);
        let tos_competencies_deltas = separate_deltas(tos_competencies_raw);
        let activity_logs_deltas = separate_deltas(activity_logs_raw);
        let school_details_deltas = separate_deltas(school_details_raw);
        let learner_details_deltas = separate_deltas(learner_details_raw);
        let attendance_records_deltas = separate_deltas(attendance_records_raw);
        let core_values_records_deltas = separate_deltas(core_values_records_raw);
        let student_school_history_deltas = separate_deltas(student_school_history_raw);
        let previous_school_subjects_deltas = separate_deltas(previous_school_subjects_raw);
        let previous_school_attendance_deltas = separate_deltas(previous_school_attendance_raw);

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
                grade_configs: grade_configs_deltas,
                grade_items: grade_items_deltas,
                grade_scores: grade_scores_deltas,
                term_grades: term_grades_deltas,
                table_of_specifications: tos_deltas,
                tos_competencies: tos_competencies_deltas,
                activity_logs: activity_logs_deltas,
                school_details: school_details_deltas,
                learner_details: learner_details_deltas,
                attendance_records: attendance_records_deltas,
                core_values_records: core_values_records_deltas,
                student_school_history: student_school_history_deltas,
                previous_school_subjects: previous_school_subjects_deltas,
                previous_school_attendance: previous_school_attendance_deltas,
            },
        })
    }
}
