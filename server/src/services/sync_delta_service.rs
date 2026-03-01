use chrono::{Duration, NaiveDateTime, Utc};
use serde_json::Value;
use std::sync::Arc;
use uuid::Uuid;

use crate::db::repositories::manifest_repository::ManifestRepository;
use crate::services::entitlement_service::EntitlementService;
use crate::utils::{AppError, AppResult};

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
}

impl SyncDeltaService {
    pub fn new(
        entitlement_service: Arc<EntitlementService>,
        manifest_repo: ManifestRepository,
    ) -> Self {
        Self {
            entitlement_service,
            manifest_repo,
        }
    }

    /// Get delta sync data since last_sync_at
    pub async fn get_deltas(
        &self,
        user_id: Uuid,
        user_role: &str,
        request: DeltaRequest,
    ) -> AppResult<DeltaResponse> {
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
            return Ok(DeltaResponse::DataExpired {
                status: "data_expired".to_string(),
                message: "Data is stale. Please perform a full sync.".to_string(),
            });
        }

        // Step 3: Get user's entitled IDs
        let manifest = self
            .entitlement_service
            .get_user_manifest(user_id, user_role)
            .await?;

        // Step 4: Query for deltas per entity type
        let classes = self
            .manifest_repo
            .get_classes_since(manifest.classes.iter().map(|e| e.id).collect(), last_sync_at)
            .await?;

        let enrollments = self
            .manifest_repo
            .get_enrollments_since(
                manifest.enrollments.iter().map(|e| e.id).collect(),
                last_sync_at,
            )
            .await?;

        let assessments = self
            .manifest_repo
            .get_assessments_since(
                manifest.assessments.iter().map(|e| e.id).collect(),
                last_sync_at,
            )
            .await?;

        let question_ids: Vec<Uuid> = manifest.assessment_questions.iter().map(|e| e.id).collect();
        let questions = if question_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo
                .get_questions_since(question_ids, last_sync_at)
                .await?
        };

        let assessment_submission_ids: Vec<Uuid> =
            manifest.assessment_submissions.iter().map(|e| e.id).collect();
        let assessment_submissions = if assessment_submission_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo
                .get_assessment_submissions_since(user_id, assessment_submission_ids, last_sync_at)
                .await?
        };

        let assignments = self
            .manifest_repo
            .get_assignments_since(
                manifest.assignments.iter().map(|e| e.id).collect(),
                last_sync_at,
            )
            .await?;

        let assignment_submission_ids: Vec<Uuid> =
            manifest.assignment_submissions.iter().map(|e| e.id).collect();
        let assignment_submissions = if assignment_submission_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo
                .get_assignment_submissions_since(user_id, assignment_submission_ids, last_sync_at)
                .await?
        };

        let learning_materials = self
            .manifest_repo
            .get_materials_since(
                manifest.learning_materials.iter().map(|e| e.id).collect(),
                last_sync_at,
            )
            .await?;

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
