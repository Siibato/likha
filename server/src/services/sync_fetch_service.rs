use serde_json::Value;
use std::collections::{HashMap, HashSet};
use uuid::Uuid;

use crate::db::repositories::manifest_repository::ManifestRepository;
use crate::db::repositories::sync_cursor_repository::SyncCursorRepository;
use crate::services::entitlement::EntitlementService;
use crate::utils::{AppError, AppResult};

/// Request for fetching stale records
#[derive(Debug, Clone, serde::Deserialize)]
pub struct FetchRequest {
    pub cursor: Option<String>,
    pub entities: HashMap<String, Vec<String>>, // {"classes": ["id1", "id2"]}
}

/// Response with paginated records
#[derive(Debug, Clone, serde::Serialize)]
pub struct FetchResponse {
    pub entities: HashMap<String, Vec<Value>>,
    pub cursor: Option<String>,
    pub has_more: bool,
}

/// Service for fetching records (paginated, resumable)
pub struct SyncFetchService {
    entitlement_service: std::sync::Arc<EntitlementService>,
    manifest_repo: ManifestRepository,
    cursor_repo: SyncCursorRepository,
}

impl SyncFetchService {
    pub fn new(
        entitlement_service: std::sync::Arc<EntitlementService>,
        manifest_repo: ManifestRepository,
        cursor_repo: SyncCursorRepository,
    ) -> Self {
        Self {
            entitlement_service,
            manifest_repo,
            cursor_repo,
        }
    }

    /// Fetch paginated records (resumable with cursor)
    pub async fn fetch_records(
        &self,
        user_id: Uuid,
        _user_role: &str,
        request: FetchRequest,
    ) -> AppResult<FetchResponse> {
        // Step 1: Verify cursor is valid (if provided)
        if let Some(ref cursor) = request.cursor {
            if !self.cursor_repo.is_cursor_valid(cursor).await? {
                return Err(AppError::BadRequest(
                    "Cursor expired or invalid".to_string(),
                ));
            }
        }

        // Step 2: Parse IDs from request
        let parsed_ids = self.parse_ids(&request.entities)?;

        // Step 3: Re-verify entitlements (manifest may have changed since Step 1)
        let entitled_manifest = self
            .entitlement_service
            .get_user_manifest(user_id, _user_role)
            .await?;

        // Build set of entitled IDs per entity type
        let mut entitled_ids: HashMap<String, HashSet<Uuid>> = HashMap::new();
        entitled_ids.insert(
            "classes".to_string(),
            entitled_manifest.classes.iter().map(|e| e.id).collect(),
        );
        entitled_ids.insert(
            "enrollments".to_string(),
            entitled_manifest.enrollments.iter().map(|e| e.id).collect(),
        );
        entitled_ids.insert(
            "assessments".to_string(),
            entitled_manifest.assessments.iter().map(|e| e.id).collect(),
        );
        entitled_ids.insert(
            "assessment_questions".to_string(),
            entitled_manifest
                .assessment_questions
                .iter()
                .map(|e| e.id)
                .collect(),
        );
        entitled_ids.insert(
            "assessment_submissions".to_string(),
            entitled_manifest
                .assessment_submissions
                .iter()
                .map(|e| e.id)
                .collect(),
        );
        entitled_ids.insert(
            "assignments".to_string(),
            entitled_manifest.assignments.iter().map(|e| e.id).collect(),
        );
        entitled_ids.insert(
            "assignment_submissions".to_string(),
            entitled_manifest
                .assignment_submissions
                .iter()
                .map(|e| e.id)
                .collect(),
        );
        entitled_ids.insert(
            "learning_materials".to_string(),
            entitled_manifest.learning_materials.iter().map(|e| e.id).collect(),
        );
        entitled_ids.insert(
            "activity_logs".to_string(),
            entitled_manifest.activity_logs.iter().map(|e| e.id).collect(),
        );

        // Filter parsed_ids to only entitled IDs (silently drop unauthorized)
        let filtered_ids: HashMap<String, Vec<Uuid>> = parsed_ids
            .into_iter()
            .map(|(entity_type, ids)| {
                let entitled_set = entitled_ids
                    .get(&entity_type)
                    .cloned()
                    .unwrap_or_default();
                let filtered = ids
                    .into_iter()
                    .filter(|id| entitled_set.contains(id))
                    .collect();
                (entity_type, filtered)
            })
            .collect();

        // Step 4: Fetch records per entity type
        let mut result_entities: HashMap<String, Vec<Value>> = HashMap::new();
        let mut has_more = false;

        for (entity_type, ids) in filtered_ids.iter() {
            if ids.is_empty() {
                continue;
            }

            let (records, entity_has_more) = match entity_type.as_str() {
                "classes" => {
                    let paginated = self
                        .manifest_repo
                        .get_classes_paginated(ids.clone(), 500)
                        .await?;
                    (paginated.records, paginated.has_more)
                }
                "enrollments" => {
                    let paginated = self
                        .manifest_repo
                        .get_enrollments_paginated(ids.clone(), 500)
                        .await?;
                    (paginated.records, paginated.has_more)
                }
                "assessments" => {
                    let paginated = self
                        .manifest_repo
                        .get_assessments_paginated(ids.clone(), 500)
                        .await?;
                    (paginated.records, paginated.has_more)
                }
                "assessment_questions" => {
                    let paginated = self
                        .manifest_repo
                        .get_questions_paginated(ids.clone(), 500)
                        .await?;
                    (paginated.records, paginated.has_more)
                }
                "assessment_submissions" => {
                    let paginated = self
                        .manifest_repo
                        .get_assessment_submissions_paginated(user_id, ids.clone(), 500)
                        .await?;
                    (paginated.records, paginated.has_more)
                }
                "assignments" => {
                    let paginated = self
                        .manifest_repo
                        .get_assignments_paginated(ids.clone(), 500)
                        .await?;
                    (paginated.records, paginated.has_more)
                }
                "assignment_submissions" => {
                    let paginated = self
                        .manifest_repo
                        .get_assignment_submissions_paginated(user_id, ids.clone(), 500)
                        .await?;
                    (paginated.records, paginated.has_more)
                }
                "learning_materials" => {
                    let paginated = self
                        .manifest_repo
                        .get_materials_paginated(ids.clone(), 500)
                        .await?;
                    (paginated.records, paginated.has_more)
                }
                "activity_logs" => {
                    let paginated = self
                        .manifest_repo
                        .get_activity_logs_paginated(ids.clone(), 500)
                        .await?;
                    (paginated.records, paginated.has_more)
                }
                _ => {
                    return Err(AppError::BadRequest(format!(
                        "Unknown entity type: {}",
                        entity_type
                    )))
                }
            };

            result_entities.insert(entity_type.clone(), records);
            if entity_has_more {
                has_more = true;
            }
        }

        // Step 5: Generate new cursor if there are more records
        let new_cursor = if has_more {
            Some(self.cursor_repo.create_cursor(user_id, "mixed", 1).await?)
        } else {
            None
        };

        Ok(FetchResponse {
            entities: result_entities,
            cursor: new_cursor,
            has_more,
        })
    }

    /// Parse entity IDs from request
    /// NOTE: Authorization is verified in manifest phase, so we trust these IDs
    fn parse_ids(
        &self,
        requested_entities: &HashMap<String, Vec<String>>,
    ) -> AppResult<HashMap<String, Vec<Uuid>>> {
        let mut result: HashMap<String, Vec<Uuid>> = HashMap::new();

        for (entity_type, id_strs) in requested_entities.iter() {
            let mut uuids = Vec::new();

            for id_str in id_strs {
                let uuid = Uuid::parse_str(id_str).map_err(|_| {
                    AppError::BadRequest(format!("Invalid UUID: {}", id_str))
                })?;
                uuids.push(uuid);
            }

            result.insert(entity_type.clone(), uuids);
        }

        Ok(result)
    }

}
