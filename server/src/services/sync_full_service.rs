use chrono::Utc;
use serde_json::Value;
use std::sync::Arc;
use uuid::Uuid;

use crate::db::repositories::manifest_repository::ManifestRepository;
use crate::services::entitlement::EntitlementService;
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
    pub enrolled_students: Vec<Value>,
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

        // Extract unique student IDs from enrollments
        let student_ids: Vec<Uuid> = enrollment_data
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

        tracing::debug!("Fetching {} enrolled students for user_id={}", student_ids.len(), user_id);
        let enrolled_students = if student_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo
                .get_users_paginated(student_ids, 10000)
                .await?
                .records
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

        let assessment_submission_ids: Vec<Uuid> =
            manifest.assessment_submissions.iter().map(|e| e.id).collect();
        tracing::debug!("Fetching {} assessment submissions for user_id={}", assessment_submission_ids.len(), user_id);
        let assessment_submissions = if assessment_submission_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo
                .get_assessment_submissions_paginated(user_id, assessment_submission_ids, 10000)
                .await?
                .records
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

        let assignment_submission_ids: Vec<Uuid> =
            manifest.assignment_submissions.iter().map(|e| e.id).collect();
        tracing::debug!("Fetching {} assignment submissions for user_id={}", assignment_submission_ids.len(), user_id);
        let assignment_submissions = if assignment_submission_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo
                .get_assignment_submissions_paginated(user_id, assignment_submission_ids, 10000)
                .await?
                .records
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
            questions,
            assessment_submissions,
            assignments,
            assignment_submissions,
            learning_materials,
        })
    }
}
