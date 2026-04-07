use uuid::Uuid;
use crate::utils::AppResult;
use crate::db::repositories::manifest_repository::ManifestEntry;

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
    #[allow(dead_code)]
    pub activity_logs: Vec<ManifestEntry>,
}

impl super::EntitlementService {
    pub async fn get_user_manifest(
        &self,
        user_id: Uuid,
        user_role: &str,
    ) -> AppResult<UserManifest> {
        let accessible_class_ids = self
            .entitlement_repo
            .get_user_accessible_classes(user_id, user_role)
            .await?;

        let activity_logs = self
            .manifest_repo
            .get_activity_logs_manifest(user_id, user_role)
            .await?;

        if accessible_class_ids.is_empty() {
            return Ok(UserManifest {
                classes: Vec::new(),
                enrollments: Vec::new(),
                assessments: Vec::new(),
                assessment_questions: Vec::new(),
                assessment_submissions: Vec::new(),
                assignments: Vec::new(),
                assignment_submissions: Vec::new(),
                learning_materials: Vec::new(),
                activity_logs,
            });
        }

        let classes = self
            .manifest_repo
            .get_classes_manifest(accessible_class_ids.clone())
            .await?;

        let enrollments = self
            .manifest_repo
            .get_enrollments_manifest(accessible_class_ids.clone(), user_id, user_role)
            .await?;

        let assessments = if user_role == "student" {
            self.manifest_repo
                .get_published_assessments_manifest(accessible_class_ids.clone())
                .await?
        } else {
            self.manifest_repo
                .get_assessments_manifest(accessible_class_ids.clone())
                .await?
        };

        let assessment_ids: Vec<Uuid> = assessments.iter().map(|a| a.id).collect();
        tracing::debug!("Manifest building: Found {} assessments", assessment_ids.len());

        let assessment_questions = if assessment_ids.is_empty() {
            tracing::debug!("Manifest building: No assessments found, skipping questions");
            Vec::new()
        } else {
            tracing::debug!("Manifest building: Fetching questions for {} assessments", assessment_ids.len());
            let questions = self.manifest_repo
                .get_questions_manifest(assessment_ids.clone())
                .await?;
            tracing::debug!("Manifest building: Found {} questions for {} assessments", questions.len(), assessment_ids.len());
            if questions.is_empty() {
                tracing::debug!("Manifest building: No questions found for assessments");
            }
            questions
        };

        let assessment_submissions = if assessment_ids.is_empty() {
            Vec::new()
        } else {
            self.manifest_repo
                .get_assessment_submissions_manifest(user_id, assessment_ids)
                .await?
        };

        let assignments = if user_role == "student" {
            self.manifest_repo
                .get_published_assignments_manifest(accessible_class_ids.clone())
                .await?
        } else {
            self.manifest_repo
                .get_assignments_manifest(accessible_class_ids.clone())
                .await?
        };

        let assignment_ids: Vec<Uuid> = assignments.iter().map(|a| a.id).collect();
        let assignment_submissions = if assignment_ids.is_empty() {
            Vec::new()
        } else if user_role == "student" {
            self.manifest_repo
                .get_assignment_submissions_manifest(user_id, assignment_ids)
                .await?
        } else {
            // teacher/admin: fetch all students' submissions for their assignments
            self.manifest_repo
                .get_all_assignment_submissions_manifest(assignment_ids)
                .await?
        };

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
            activity_logs,
        })
    }
}