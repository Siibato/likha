use chrono::Utc;
use serde_json::Value;
use std::sync::Arc;
use uuid::Uuid;

use crate::db::repositories::manifest_repository::ManifestRepository;
use crate::services::entitlement_service::EntitlementService;
use crate::utils::AppResult;

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
    pub assessments: Vec<Value>,
    pub questions: Vec<Value>,
    pub assessment_submissions: Vec<Value>,
    pub assignments: Vec<Value>,
    pub assignment_submissions: Vec<Value>,
    pub learning_materials: Vec<Value>,
}

/// Service for full sync on login
pub struct SyncFullService {
    entitlement_service: Arc<EntitlementService>,
    manifest_repo: ManifestRepository,
}

impl SyncFullService {
    pub fn new(
        entitlement_service: Arc<EntitlementService>,
        manifest_repo: ManifestRepository,
    ) -> Self {
        Self {
            entitlement_service,
            manifest_repo,
        }
    }

    /// Get full sync data for user
    pub async fn get_full_sync(
        &self,
        user_id: Uuid,
        user_role: &str,
        _request: FullSyncRequest,
    ) -> AppResult<FullSyncResponse> {
        // Step 1: Get all records user is entitled to
        let manifest = self
            .entitlement_service
            .get_user_manifest(user_id, user_role)
            .await?;

        // Step 2: Fetch full records for each entity type
        let classes = self
            .manifest_repo
            .get_classes_paginated(
                manifest.classes.iter().map(|e| e.id).collect(),
                10000,
            )
            .await?
            .records;

        let enrollments = self
            .manifest_repo
            .get_enrollments_paginated(
                manifest.enrollments.iter().map(|e| e.id).collect(),
                10000,
            )
            .await?
            .records;

        let assessments = self
            .manifest_repo
            .get_assessments_paginated(
                manifest.assessments.iter().map(|e| e.id).collect(),
                10000,
            )
            .await?
            .records;

        let question_ids: Vec<Uuid> = manifest.assessment_questions.iter().map(|e| e.id).collect();
        let questions = if question_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo
                .get_questions_paginated(question_ids, 10000)
                .await?
                .records
        };

        let assessment_submission_ids: Vec<Uuid> =
            manifest.assessment_submissions.iter().map(|e| e.id).collect();
        let assessment_submissions = if assessment_submission_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo
                .get_assessment_submissions_paginated(user_id, assessment_submission_ids, 10000)
                .await?
                .records
        };

        let assignments = self
            .manifest_repo
            .get_assignments_paginated(
                manifest.assignments.iter().map(|e| e.id).collect(),
                10000,
            )
            .await?
            .records;

        let assignment_submission_ids: Vec<Uuid> =
            manifest.assignment_submissions.iter().map(|e| e.id).collect();
        let assignment_submissions = if assignment_submission_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo
                .get_assignment_submissions_paginated(user_id, assignment_submission_ids, 10000)
                .await?
                .records
        };

        let learning_materials = self
            .manifest_repo
            .get_materials_paginated(
                manifest.learning_materials.iter().map(|e| e.id).collect(),
                10000,
            )
            .await?
            .records;

        let now = Utc::now();
        let sync_token = now.to_rfc3339();
        let server_time = now.to_rfc3339();

        Ok(FullSyncResponse {
            sync_token,
            server_time,
            user: None, // TODO: include user data if needed
            classes,
            enrollments,
            assessments,
            questions,
            assessment_submissions,
            assignments,
            assignment_submissions,
            learning_materials,
        })
    }
}
