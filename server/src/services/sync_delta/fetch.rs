use chrono::{Duration, NaiveDateTime, Utc};
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use crate::services::sync_common::enrich_questions;

use super::sync_delta_service::{DeltaRequest, DeltaResponse, DeltaPayload, EntityDeltas};
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
            enrich_questions(&self.db, raw_questions, user_role).await?
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

        // Step 5: Fetch grading deltas
        let class_ids: Vec<Uuid> = manifest.classes.iter().map(|e| e.id).collect();
        let grade_configs_raw = self.manifest_repo
            .get_grade_configs_since(class_ids.clone(), last_sync_at)
            .await?;
        let grade_items_raw = self.manifest_repo
            .get_grade_items_since(class_ids.clone(), last_sync_at)
            .await?;

        // Get all grade_item IDs for score delta query
        let all_grade_item_ids: Vec<Uuid> = self.manifest_repo
            .get_grade_item_ids_for_classes(class_ids.clone())
            .await?;

        let grade_scores_raw = if all_grade_item_ids.is_empty() {
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

        let quarterly_grades_raw = match user_role {
            "student" => self.manifest_repo
                .get_student_quarterly_grades_since(user_id, class_ids, last_sync_at)
                .await?,
            _ => self.manifest_repo
                .get_all_quarterly_grades_since(class_ids, last_sync_at)
                .await?,
        };

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
        let quarterly_grades_deltas = separate_deltas(quarterly_grades_raw);

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
                quarterly_grades: quarterly_grades_deltas,
                table_of_specifications: EntityDeltas { updated: vec![], deleted: vec![] },
                tos_competencies: EntityDeltas { updated: vec![], deleted: vec![] },
            },
        })
    }
}
