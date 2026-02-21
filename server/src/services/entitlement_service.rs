use serde_json::{json, Value};
use uuid::Uuid;

use crate::db::repositories::entitlement_repository::EntitlementRepository;
use crate::db::repositories::manifest_repository::{ManifestRepository, ManifestEntry};
use crate::utils::{AppError, AppResult};

/// Contains all records user is entitled to access (for manifest)
#[derive(Debug, Clone)]
pub struct UserManifest {
    pub classes: Vec<ManifestEntry>,
    pub enrollments: Vec<ManifestEntry>,
    pub assessments: Vec<ManifestEntry>,
    pub assessment_questions: Vec<ManifestEntry>,
    pub assessment_submissions: Vec<ManifestEntry>,
    pub assignments: Vec<ManifestEntry>,
    pub assignment_submissions: Vec<ManifestEntry>,
    pub learning_materials: Vec<ManifestEntry>,
}

impl UserManifest {
    /// Convert to JSON format for API response
    pub fn to_json(&self) -> Value {
        json!({
            "classes": self.classes.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>(),
            "enrollments": self.enrollments.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>(),
            "assessments": self.assessments.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>(),
            "assessment_questions": self.assessment_questions.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>(),
            "assessment_submissions": self.assessment_submissions.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>(),
            "assignments": self.assignments.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>(),
            "assignment_submissions": self.assignment_submissions.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>(),
            "learning_materials": self.learning_materials.iter().map(|e| json!({
                "id": e.id.to_string(),
                "updated_at": e.updated_at.to_string(),
                "deleted": e.deleted
            })).collect::<Vec<_>>(),
        })
    }
}

/// Service for managing user entitlements and building manifests
pub struct EntitlementService {
    entitlement_repo: EntitlementRepository,
    manifest_repo: ManifestRepository,
}

impl EntitlementService {
    pub fn new(
        entitlement_repo: EntitlementRepository,
        manifest_repo: ManifestRepository,
    ) -> Self {
        Self {
            entitlement_repo,
            manifest_repo,
        }
    }

    /// Build the complete manifest for a user (what they're entitled to see)
    /// This traverses: User → Enrollments → Classes → Assessments/Assignments/Materials
    pub async fn get_user_manifest(
        &self,
        user_id: Uuid,
        user_role: &str,
    ) -> AppResult<UserManifest> {
        // Step 1: Get classes user is entitled to
        let accessible_class_ids = self
            .entitlement_repo
            .get_user_accessible_classes(user_id, user_role)
            .await?;

        if accessible_class_ids.is_empty() {
            // User has no classes - return empty manifest
            return Ok(UserManifest {
                classes: Vec::new(),
                enrollments: Vec::new(),
                assessments: Vec::new(),
                assessment_questions: Vec::new(),
                assessment_submissions: Vec::new(),
                assignments: Vec::new(),
                assignment_submissions: Vec::new(),
                learning_materials: Vec::new(),
            });
        }

        // Step 2: Get manifest entries for classes
        let classes = self
            .manifest_repo
            .get_classes_manifest(accessible_class_ids.clone())
            .await?;

        // Step 3: Get enrollments (for students)
        let enrollments = self
            .manifest_repo
            .get_enrollments_manifest(accessible_class_ids.clone())
            .await?;

        // Step 4: Get assessments in those classes
        let assessments = self
            .manifest_repo
            .get_assessments_manifest(accessible_class_ids.clone())
            .await?;

        // Step 5: Get assessment IDs for questions query
        let assessment_ids: Vec<Uuid> = assessments.iter().map(|a| a.id).collect();
        let assessment_questions = if assessment_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo
                .get_questions_manifest(assessment_ids.clone())
                .await?
        };

        // Step 6: Get assessment submissions (user-specific)
        let assessment_submissions = if assessment_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo
                .get_assessment_submissions_manifest(user_id, assessment_ids)
                .await?
        };

        // Step 7: Get assignments in those classes
        let assignments = self
            .manifest_repo
            .get_assignments_manifest(accessible_class_ids.clone())
            .await?;

        // Step 8: Get assignment submissions (user-specific)
        let assignment_ids: Vec<Uuid> = assignments.iter().map(|a| a.id).collect();
        let assignment_submissions = if assignment_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo
                .get_assignment_submissions_manifest(user_id, assignment_ids)
                .await?
        };

        // Step 9: Get learning materials in those classes
        let learning_materials = self
            .manifest_repo
            .get_materials_manifest(accessible_class_ids)
            .await?;

        Ok(UserManifest {
            classes,
            enrollments,
            assessments,
            assessment_questions,
            assessment_submissions,
            assignments,
            assignment_submissions,
            learning_materials,
        })
    }

    /// Verify user can perform an operation (abort early if not)
    pub async fn assert_can_sync_operation(
        &self,
        user_id: Uuid,
        user_role: &str,
        operation_type: &str,
        entity_type: &str,
        class_id: Option<Uuid>,
    ) -> AppResult<()> {
        match (entity_type, operation_type) {
            ("class", "create") => {
                // Only teachers and admins can create classes
                if user_role == "student" {
                    return Err(AppError::Forbidden(
                        "Students cannot create classes".to_string(),
                    ));
                }
                Ok(())
            }
            ("class", "update" | "delete") => {
                // Only teachers who own the class can modify it
                if let Some(class_id) = class_id {
                    self.entitlement_repo
                        .assert_can_modify_class(user_id, user_role, class_id)
                        .await?;
                }
                Ok(())
            }
            ("assessment", "create" | "update" | "delete") => {
                // Only teachers who teach the class can modify
                if let Some(class_id) = class_id {
                    self.entitlement_repo
                        .assert_can_modify_class(user_id, user_role, class_id)
                        .await?;
                }
                Ok(())
            }
            ("assessment_submission", "create" | "update") => {
                // Only students can submit assessments (for their own submissions)
                if user_role != "student" {
                    return Err(AppError::Forbidden(
                        "Only students can submit assessments".to_string(),
                    ));
                }
                Ok(())
            }
            ("assignment", "create" | "update" | "delete") => {
                // Only teachers who teach the class can modify
                if let Some(class_id) = class_id {
                    self.entitlement_repo
                        .assert_can_modify_class(user_id, user_role, class_id)
                        .await?;
                }
                Ok(())
            }
            ("assignment_submission", "create" | "update") => {
                // Only students can submit assignments (for their own submissions)
                if user_role != "student" {
                    return Err(AppError::Forbidden(
                        "Only students can submit assignments".to_string(),
                    ));
                }
                Ok(())
            }
            ("learning_material", "create" | "update" | "delete") => {
                // Only teachers who teach the class can modify
                if let Some(class_id) = class_id {
                    self.entitlement_repo
                        .assert_can_modify_class(user_id, user_role, class_id)
                        .await?;
                }
                Ok(())
            }
            _ => {
                // Unknown operation/entity combination
                Err(AppError::BadRequest(format!(
                    "Unknown operation: {} on {}",
                    operation_type, entity_type
                )))
            }
        }
    }
}
