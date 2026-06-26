use crate::modules::sync::manifest_repository::ManifestEntry;
use crate::modules::sync::sync_scope::SyncScope;
use crate::utils::AppResult;
use uuid::Uuid;

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
    pub activity_logs: Vec<ManifestEntry>,
}

impl crate::modules::entitlement::service::EntitlementService {
    pub async fn get_user_manifest(
        &self,
        user_id: Uuid,
        user_role: &str,
    ) -> AppResult<UserManifest> {
        let scope = SyncScope::for_role(user_role);

        let (accessible_class_ids, activity_logs) = tokio::try_join!(
            self.entitlement_repo
                .get_user_accessible_classes(user_id, user_role),
            self.manifest_repo
                .get_activity_logs_manifest(user_id, user_role),
        )?;

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

        // Fetch class-scoped manifests in parallel
        let (classes, enrollments, assessments, assignments, learning_materials) = tokio::try_join!(
            self.manifest_repo
                .get_classes_manifest(accessible_class_ids.clone()),
            self.manifest_repo
                .get_enrollments_manifest(accessible_class_ids.clone(), user_id, user_role),
            async {
                if scope.include_assessments {
                    if user_role == "student" {
                        self.manifest_repo
                            .get_published_assessments_manifest(accessible_class_ids.clone())
                            .await
                    } else {
                        self.manifest_repo
                            .get_assessments_manifest(accessible_class_ids.clone())
                            .await
                    }
                } else {
                    Ok(Vec::new())
                }
            },
            async {
                if scope.include_assignments {
                    if user_role == "student" {
                        self.manifest_repo
                            .get_published_assignments_manifest(accessible_class_ids.clone())
                            .await
                    } else {
                        self.manifest_repo
                            .get_assignments_manifest(accessible_class_ids.clone())
                            .await
                    }
                } else {
                    Ok(Vec::new())
                }
            },
            async {
                if scope.include_learning_materials {
                    self.manifest_repo
                        .get_materials_manifest(accessible_class_ids.clone())
                        .await
                } else {
                    Ok(Vec::new())
                }
            },
        )?;

        let assessment_ids: Vec<Uuid> = assessments.iter().map(|a| a.id).collect();
        let assignment_ids: Vec<Uuid> = assignments.iter().map(|a| a.id).collect();
        tracing::debug!(
            "Manifest building: Found {} assessments, {} assignments",
            assessment_ids.len(),
            assignment_ids.len()
        );

        let (assessment_questions, assessment_submissions, assignment_submissions) = tokio::try_join!(
            async {
                if scope.include_questions && !assessment_ids.is_empty() {
                    tracing::debug!(
                        "Manifest building: Fetching questions for {} assessments",
                        assessment_ids.len()
                    );
                    let questions = self
                        .manifest_repo
                        .get_questions_manifest(assessment_ids.clone())
                        .await?;
                    tracing::debug!(
                        "Manifest building: Found {} questions for {} assessments",
                        questions.len(),
                        assessment_ids.len()
                    );
                    if questions.is_empty() {
                        tracing::debug!("Manifest building: No questions found for assessments");
                    }
                    Ok(questions)
                } else {
                    Ok(Vec::new())
                }
            },
            async {
                if scope.include_submissions && !assessment_ids.is_empty() {
                    if user_role == "student" {
                        self.manifest_repo
                            .get_assessment_submissions_manifest(user_id, assessment_ids.clone())
                            .await
                    } else {
                        self.manifest_repo
                            .get_all_assessment_submissions_manifest(assessment_ids.clone())
                            .await
                    }
                } else {
                    Ok(Vec::new())
                }
            },
            async {
                if scope.include_submissions && !assignment_ids.is_empty() {
                    if user_role == "student" {
                        self.manifest_repo
                            .get_assignment_submissions_manifest(user_id, assignment_ids.clone())
                            .await
                    } else {
                        self.manifest_repo
                            .get_all_assignment_submissions_manifest(assignment_ids.clone())
                            .await
                    }
                } else {
                    Ok(Vec::new())
                }
            },
        )?;

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
