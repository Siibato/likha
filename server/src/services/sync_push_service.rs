use chrono::Utc;
use serde_json::Value;
use std::sync::Arc;
use uuid::Uuid;

use crate::services::entitlement_service::EntitlementService;
use crate::services::class_service::ClassService;
use crate::services::assessment_service::AssessmentService;
use crate::services::assignment_service::AssignmentService;
use crate::services::learning_material_service::LearningMaterialService;
use crate::services::auth_service::AuthService;
use crate::schema::class_schema::{CreateClassRequest, UpdateClassRequest};
use crate::schema::assessment_schema::{CreateAssessmentRequest, UpdateAssessmentRequest, SaveAnswersRequest};
use crate::schema::assignment_schema::{CreateAssignmentRequest, UpdateAssignmentRequest};
use crate::schema::learning_material_schema::{CreateMaterialRequest, UpdateMaterialRequest};
use crate::utils::AppResult;

/// Incoming sync operation from client
#[derive(Debug, Clone, serde::Deserialize)]
pub struct SyncQueueEntry {
    pub id: String,              // Local operation ID
    pub entity_type: String,     // "class", "assessment", etc.
    pub operation: String,       // "create", "update", "delete"
    pub payload: Value,          // Full entity data
}

/// Result of processing one operation
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct OperationResult {
    pub id: String,              // Matches SyncQueueEntry.id
    pub entity_type: String,
    pub operation: String,
    pub success: bool,
    pub server_id: Option<String>, // For creates
    pub error: Option<String>,
    pub updated_at: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub metadata: Option<serde_json::Value>, // For nested ID mappings
}

/// Response from push endpoint
#[derive(Debug, Clone, serde::Serialize)]
pub struct PushResponse {
    pub results: Vec<OperationResult>,
}

/// Processes offline mutations from mobile clients
pub struct SyncPushService {
    entitlement_service: Arc<EntitlementService>,
    class_service: Arc<ClassService>,
    assessment_service: Arc<AssessmentService>,
    assignment_service: Arc<AssignmentService>,
    material_service: Arc<LearningMaterialService>,
    auth_service: Arc<AuthService>,
    processed_ops_repo: Arc<crate::db::repositories::processed_operations_repository::ProcessedOperationsRepository>,
}

impl SyncPushService {
    pub fn new(
        entitlement_service: Arc<EntitlementService>,
        class_service: Arc<ClassService>,
        assessment_service: Arc<AssessmentService>,
        assignment_service: Arc<AssignmentService>,
        material_service: Arc<LearningMaterialService>,
        auth_service: Arc<AuthService>,
        processed_ops_repo: Arc<crate::db::repositories::processed_operations_repository::ProcessedOperationsRepository>,
    ) -> Self {
        Self {
            entitlement_service,
            class_service,
            assessment_service,
            assignment_service,
            material_service,
            auth_service,
            processed_ops_repo,
        }
    }

    /// Process all pending operations from client
    /// Each operation is processed independently - failures don't block others
    pub async fn push_operations(
        &self,
        user_id: Uuid,
        user_role: &str,
        payload: Value,
    ) -> AppResult<PushResponse> {
        // Parse operations from payload
        let operations: Vec<SyncQueueEntry> = match payload.get("operations") {
            Some(ops) => match serde_json::from_value(ops.clone()) {
                Ok(ops) => ops,
                Err(_) => {
                    return Ok(PushResponse {
                        results: vec![],
                    })
                }
            },
            None => vec![],
        };

        let mut results = Vec::new();

        // Process each operation independently
        for op in operations {
            // ✅ CHECK IF ALREADY PROCESSED (DEDUPLICATION)
            if let Ok(Some(cached_result)) = self.processed_ops_repo.check_processed(&op.id).await {
                results.push(cached_result);
                continue;
            }

            let result = self.process_single_operation(user_id, user_role, &op).await;

            // ✅ SAVE RESULT BEFORE RETURNING (ENABLES DEDUP ON RETRY)
            let _ = self.processed_ops_repo.save_processed(
                &op.id,
                user_id,
                &op.entity_type,
                &op.operation,
                &result,
            ).await;

            results.push(result);
        }

        Ok(PushResponse { results })
    }

    /// Process a single operation and return its result
    /// Operation failures are captured in OperationResult, not propagated as errors
    async fn process_single_operation(
        &self,
        user_id: Uuid,
        user_role: &str,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        // Check authorization first
        let class_id = op.payload.get("class_id").and_then(|v| {
            v.as_str().and_then(|s| Uuid::parse_str(s).ok())
        });

        if let Err(_e) = self
            .entitlement_service
            .assert_can_sync_operation(user_id, user_role, &op.operation, &op.entity_type, class_id)
            .await
        {
            return OperationResult {
                id: op.id.clone(),
                entity_type: op.entity_type.clone(),
                operation: op.operation.clone(),
                success: false,
                server_id: None,
                error: Some("Authorization failed".to_string()),
                updated_at: None,
                metadata: None,
            };
        }

        // Route to appropriate handler
        match op.entity_type.as_str() {
            "class" => self.handle_class_operation(user_id, op).await,
            "admin_user" => self.handle_admin_user_operation(user_id, op).await,
            "assessment" => self.handle_assessment_operation(user_id, user_role, op).await,
            "question" => self.handle_question_operation(user_id, op).await,
            "assignment" => self.handle_assignment_operation(user_id, user_role, op).await,
            "learning_material" => self.handle_learning_material_operation(user_id, op).await,
            "assessment_submission" => {
                self.handle_assessment_submission_operation(user_id, op).await
            }
            "assignment_submission" => {
                self.handle_assignment_submission_operation(user_id, op).await
            }
            "submission_file" => {
                self.handle_submission_file_operation(user_id, op).await
            }
            "material_file" => {
                self.handle_material_file_operation(user_id, op).await
            }
            "activity_log" => {
                self.handle_activity_log_operation(user_id, op).await
            }
            _ => OperationResult {
                id: op.id.clone(),
                entity_type: op.entity_type.clone(),
                operation: op.operation.clone(),
                success: false,
                server_id: None,
                error: Some(format!("Unknown entity type: {}", op.entity_type)),
                updated_at: None,
                metadata: None,
            },
        }
    }

    /// Handle class operations (create, update, delete)
    async fn handle_class_operation(
        &self,
        user_id: Uuid,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let title = match op.payload.get("title").and_then(|v| v.as_str()) {
                    Some(t) => t.to_string(),
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing title field".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let description = op
                    .payload
                    .get("description")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());

                let request = CreateClassRequest { title, description };

                match self.class_service.create_class(request, user_id).await {
                    Ok(response) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: Some(response.id.to_string()),
                        error: None,
                        updated_at: Some(response.updated_at),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "update" => {
                let class_id = match op.payload.get("id").and_then(|v| v.as_str()) {
                    Some(id) => match Uuid::parse_str(id) {
                        Ok(id) => id,
                        Err(_) => {
                            return OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some("Invalid class ID".to_string()),
                                updated_at: None,
                                metadata: None,
                            };
                        }
                    },
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing id field".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let title = op.payload.get("title").and_then(|v| v.as_str()).map(|s| s.to_string());
                let description = op.payload.get("description").and_then(|v| v.as_str()).map(|s| s.to_string());

                let request = UpdateClassRequest { title, description };

                match self.class_service.update_class(class_id, request, user_id).await {
                    Ok(response) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(response.updated_at),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "delete" => {
                let class_id = match op.payload.get("id").and_then(|v| v.as_str()) {
                    Some(id) => match Uuid::parse_str(id) {
                        Ok(id) => id,
                        Err(_) => {
                            return OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some("Invalid class ID".to_string()),
                                updated_at: None,
                                metadata: None,
                            };
                        }
                    },
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing id field".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                match self.class_service.soft_delete(class_id, user_id).await {
                    Ok(_) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "add_enrollment" => {
                let class_id = match op.payload.get("class_id").and_then(|v| v.as_str()) {
                    Some(id) => match Uuid::parse_str(id) {
                        Ok(id) => id,
                        Err(_) => {
                            return OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some("Invalid class ID".to_string()),
                                updated_at: None,
                                metadata: None,
                            };
                        }
                    },
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing class_id field".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let student_id = match op.payload.get("student_id").and_then(|v| v.as_str()) {
                    Some(id) => match Uuid::parse_str(id) {
                        Ok(id) => id,
                        Err(_) => {
                            return OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some("Invalid student ID".to_string()),
                                updated_at: None,
                                metadata: None,
                            };
                        }
                    },
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing student_id field".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                // Idempotency check: if already enrolled, treat as success
                let already_enrolled = self.class_service
                    .is_student_enrolled(class_id, student_id)
                    .await
                    .unwrap_or(false);

                if already_enrolled {
                    return OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None, // existing enrollment ID not fetched, that's ok
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    };
                }

                match self.class_service.add_student(class_id, student_id, user_id).await {
                    Ok(enrollment_response) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: Some(enrollment_response.id.to_string()),
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "remove_enrollment" => {
                let class_id = match op.payload.get("class_id").and_then(|v| v.as_str()) {
                    Some(id) => match Uuid::parse_str(id) {
                        Ok(id) => id,
                        Err(_) => {
                            return OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some("Invalid class ID".to_string()),
                                updated_at: None,
                                metadata: None,
                            };
                        }
                    },
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing class_id field".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let student_id = match op.payload.get("student_id").and_then(|v| v.as_str()) {
                    Some(id) => match Uuid::parse_str(id) {
                        Ok(id) => id,
                        Err(_) => {
                            return OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some("Invalid student ID".to_string()),
                                updated_at: None,
                                metadata: None,
                            };
                        }
                    },
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing student_id field".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                match self.class_service.remove_student(class_id, student_id, user_id).await {
                    Ok(_) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            _ => OperationResult {
                id: op.id.clone(),
                entity_type: op.entity_type.clone(),
                operation: op.operation.clone(),
                success: false,
                server_id: None,
                error: Some(format!("Unknown operation: {}", op.operation)),
                updated_at: None,
                metadata: None,
            },
        }
    }

    /// Handle admin user operations (create, update)
    async fn handle_admin_user_operation(
        &self,
        user_id: Uuid,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let username = match op.payload.get("username").and_then(|v| v.as_str()) {
                    Some(u) => u.to_string(),
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing username field".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let full_name = match op.payload.get("full_name").and_then(|v| v.as_str()) {
                    Some(n) => n.to_string(),
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing full_name field".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let role = match op.payload.get("role").and_then(|v| v.as_str()) {
                    Some(r) => r.to_string(),
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing role field".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                use crate::schema::auth_schema::CreateAccountRequest;

                let request = CreateAccountRequest {
                    username,
                    full_name,
                    role,
                };

                match self.auth_service.create_account(request, user_id).await {
                    Ok(user) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: Some(user.id.to_string()),
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "update" => {
                let target_user_id = match op.payload.get("id").and_then(|v| v.as_str()) {
                    Some(id) => match Uuid::parse_str(id) {
                        Ok(parsed_id) => parsed_id,
                        Err(_) => {
                            return OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some("Invalid user ID".to_string()),
                                updated_at: None,
                                metadata: None,
                            };
                        }
                    },
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing id field".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let action = op.payload.get("action").and_then(|v| v.as_str()).unwrap_or("update");

                match action {
                    "update" => {
                        let username = op.payload.get("username").and_then(|v| v.as_str()).map(|s| s.to_string());
                        let full_name = op.payload.get("full_name").and_then(|v| v.as_str()).map(|s| s.to_string());

                        use crate::schema::auth_schema::UpdateAccountRequest;

                        let request = UpdateAccountRequest {
                            username,
                            full_name,
                        };

                        match self.auth_service.update_account(target_user_id, request, user_id).await {
                            Ok(updated_user) => OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: true,
                                server_id: None,
                                error: None,
                                updated_at: Some(Utc::now().to_rfc3339()),
                                metadata: None,
                            },
                            Err(e) => OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some(e.to_string()),
                                updated_at: None,
                                metadata: None,
                            },
                        }
                    }
                    "reset" => {
                        use crate::schema::auth_schema::ResetAccountRequest;

                        let request = ResetAccountRequest {
                            user_id: target_user_id,
                        };

                        match self.auth_service.reset_account(request, user_id).await {
                            Ok(_) => OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: true,
                                server_id: None,
                                error: None,
                                updated_at: Some(Utc::now().to_rfc3339()),
                                metadata: None,
                            },
                            Err(e) => OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some(e.to_string()),
                                updated_at: None,
                                metadata: None,
                            },
                        }
                    }
                    "lock" => {
                        let locked = op.payload.get("locked").and_then(|v| v.as_bool()).unwrap_or(true);

                        use crate::schema::auth_schema::LockAccountRequest;

                        let request = LockAccountRequest {
                            user_id: target_user_id,
                            locked,
                        };

                        match self.auth_service.lock_account(request, user_id).await {
                            Ok(_) => OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: true,
                                server_id: None,
                                error: None,
                                updated_at: Some(Utc::now().to_rfc3339()),
                                metadata: None,
                            },
                            Err(e) => OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some(e.to_string()),
                                updated_at: None,
                                metadata: None,
                            },
                        }
                    }
                    _ => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(format!("Unknown action for admin_user update: {}", action)),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            _ => OperationResult {
                id: op.id.clone(),
                entity_type: op.entity_type.clone(),
                operation: op.operation.clone(),
                success: false,
                server_id: None,
                error: Some(format!("Unsupported operation for admin_user: {}", op.operation)),
                updated_at: None,
                metadata: None,
            },
        }
    }

    /// Handle assessment operations (create, update, delete)
    async fn handle_assessment_operation(
        &self,
        user_id: Uuid,
        user_role: &str,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                // Parse required fields
                let class_id = match op.payload.get("class_id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid class_id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let title = match op.payload.get("title").and_then(|v| v.as_str()) {
                    Some(t) => t.to_string(),
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing title field".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let description = op.payload.get("description").and_then(|v| v.as_str()).map(|s| s.to_string());
                let time_limit = op.payload.get("time_limit_minutes").and_then(|v| v.as_i64()).unwrap_or(30) as i32;
                let open_at = op.payload.get("open_at").and_then(|v| v.as_str()).map(|s| s.to_string()).unwrap_or_else(|| Utc::now().to_rfc3339());
                let close_at = op.payload.get("close_at").and_then(|v| v.as_str()).map(|s| s.to_string()).unwrap_or_else(|| Utc::now().checked_add_signed(chrono::Duration::hours(1)).unwrap().to_rfc3339());

                let request = CreateAssessmentRequest {
                    title,
                    description,
                    time_limit_minutes: time_limit,
                    open_at,
                    close_at,
                    show_results_immediately: None,
                };

                match self.assessment_service.create_assessment(
                    class_id,
                    request,
                    user_id,
                ).await {
                    Ok(response) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: Some(response.id.to_string()),
                        error: None,
                        updated_at: Some(response.updated_at),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "update" => {
                let assessment_id = match op.payload.get("id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid assessment id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let title = op.payload.get("title").and_then(|v| v.as_str()).map(|s| s.to_string());
                let description = op.payload.get("description").and_then(|v| v.as_str()).map(|s| s.to_string());
                let time_limit = op.payload.get("time_limit_minutes").and_then(|v| v.as_i64()).map(|v| v as i32);
                let open_at = op.payload.get("open_at").and_then(|v| v.as_str()).map(|s| s.to_string());
                let close_at = op.payload.get("close_at").and_then(|v| v.as_str()).map(|s| s.to_string());

                let request = UpdateAssessmentRequest {
                    title,
                    description,
                    time_limit_minutes: time_limit,
                    open_at,
                    close_at,
                    show_results_immediately: None,
                };

                match self.assessment_service.update_assessment(assessment_id, request, user_id).await {
                    Ok(response) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(response.updated_at),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "delete" => {
                let assessment_id = match op.payload.get("id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid assessment id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                match self.assessment_service.soft_delete(assessment_id, user_id, user_role).await {
                    Ok(_) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "publish" => {
                let assessment_id = match op.payload.get("id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid assessment id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                match self.assessment_service.publish_assessment(assessment_id, user_id).await {
                    Ok(_response) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "release_results" => {
                let assessment_id = match op.payload.get("id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid assessment id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                match self.assessment_service.release_results(assessment_id, user_id).await {
                    Ok(_) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            _ => OperationResult {
                id: op.id.clone(),
                entity_type: op.entity_type.clone(),
                operation: op.operation.clone(),
                success: false,
                server_id: None,
                error: Some(format!("Unknown operation: {}", op.operation)),
                updated_at: None,
                metadata: None,
            },
        }
    }

    /// Handle question operations (create, update, delete)
    async fn handle_question_operation(
        &self,
        user_id: Uuid,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        use crate::schema::assessment_schema::{AddQuestionRequest, UpdateQuestionRequest, AddQuestionsRequest, ChoiceInput, EnumerationItemInput};

        match op.operation.as_str() {
            "create" => {
                let assessment_id = match op.payload.get("assessment_id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid assessment_id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                // Get questions array from payload
                let questions_array = match op.payload.get("questions").and_then(|v| v.as_array()) {
                    Some(arr) => arr,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid questions array".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                // Parse all questions from the array
                let mut questions = Vec::new();
                for q in questions_array {
                    let question_type = match q.get("question_type").and_then(|v| v.as_str()) {
                        Some(t) => t.to_string(),
                        None => {
                            return OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some("Missing question_type field".to_string()),
                                updated_at: None,
                                metadata: None,
                            };
                        }
                    };

                    let question_text = match q.get("question_text").and_then(|v| v.as_str()) {
                        Some(t) => t.to_string(),
                        None => {
                            return OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some("Missing question_text field".to_string()),
                                updated_at: None,
                                metadata: None,
                            };
                        }
                    };

                    let points = match q.get("points").and_then(|v| v.as_i64()) {
                        Some(p) => p as i32,
                        None => {
                            return OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some("Missing points field".to_string()),
                                updated_at: None,
                                metadata: None,
                            };
                        }
                    };

                    let order_index = q.get("order_index").and_then(|v| v.as_i64()).unwrap_or(0) as i32;
                    let is_multi_select = q.get("is_multi_select").and_then(|v| v.as_bool());

                    // Parse choices if present
                    let choices = q.get("choices").and_then(|v| v.as_array()).map(|arr| {
                        arr.iter()
                            .filter_map(|c| {
                                let choice_text = c.get("choice_text").and_then(|v| v.as_str())?.to_string();
                                let is_correct = c.get("is_correct").and_then(|v| v.as_bool()).unwrap_or(false);
                                let order_index = c.get("order_index").and_then(|v| v.as_i64()).unwrap_or(0) as i32;
                                Some(ChoiceInput { choice_text, is_correct, order_index })
                            })
                            .collect::<Vec<_>>()
                    });

                    // Parse correct answers if present
                    let correct_answers = q.get("correct_answers").and_then(|v| v.as_array()).map(|arr| {
                        arr.iter()
                            .filter_map(|a| a.get("answer_text").and_then(|v| v.as_str()).map(|s| s.to_string()))
                            .collect::<Vec<_>>()
                    });

                    // Parse enumeration items if present
                    let enumeration_items = q.get("enumeration_items").and_then(|v| v.as_array()).map(|arr| {
                        arr.iter()
                            .filter_map(|item| {
                                let order_index = item.get("order_index").and_then(|v| v.as_i64()).unwrap_or(0) as i32;
                                let acceptable_answers = item.get("acceptable_answers")
                                    .and_then(|v| v.as_array())
                                    .map(|a| a.iter().filter_map(|s| s.as_str().map(|s| s.to_string())).collect::<Vec<_>>())
                                    .unwrap_or_default();
                                Some(EnumerationItemInput { order_index, acceptable_answers })
                            })
                            .collect::<Vec<_>>()
                    });

                    questions.push(AddQuestionRequest {
                        question_type,
                        question_text,
                        points,
                        order_index,
                        is_multi_select,
                        choices,
                        correct_answers,
                        enumeration_items,
                    });
                }

                let request = AddQuestionsRequest { questions };

                match self.assessment_service.add_questions(assessment_id, request, user_id).await {
                    Ok(mut responses) => {
                        if let Some(first_response) = responses.pop() {
                            OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: true,
                                server_id: Some(first_response.id.to_string()),
                                error: None,
                                updated_at: Some(Utc::now().to_rfc3339()),
                                metadata: None,
                            }
                        } else {
                            OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some("No questions returned from server".to_string()),
                                updated_at: None,
                                metadata: None,
                            }
                        }
                    }
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "update" => {
                let question_id = match op.payload.get("id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid question id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let question_text = op.payload.get("question_text").and_then(|v| v.as_str()).map(|s| s.to_string());
                let points = op.payload.get("points").and_then(|v| v.as_i64()).map(|v| v as i32);
                let order_index = op.payload.get("order_index").and_then(|v| v.as_i64()).map(|v| v as i32);
                let is_multi_select = op.payload.get("is_multi_select").and_then(|v| v.as_bool());

                // Parse choices if present
                let choices = op.payload.get("choices").and_then(|v| v.as_array()).map(|arr| {
                    arr.iter()
                        .filter_map(|c| {
                            let choice_text = c.get("choice_text").and_then(|v| v.as_str())?.to_string();
                            let is_correct = c.get("is_correct").and_then(|v| v.as_bool()).unwrap_or(false);
                            let order_index = c.get("order_index").and_then(|v| v.as_i64()).unwrap_or(0) as i32;
                            Some(ChoiceInput { choice_text, is_correct, order_index })
                        })
                        .collect::<Vec<_>>()
                });

                // Parse correct answers if present
                let correct_answers = op.payload.get("correct_answers").and_then(|v| v.as_array()).map(|arr| {
                    arr.iter()
                        .filter_map(|a| a.get("answer_text").and_then(|v| v.as_str()).map(|s| s.to_string()))
                        .collect::<Vec<_>>()
                });

                // Parse enumeration items if present
                let enumeration_items = op.payload.get("enumeration_items").and_then(|v| v.as_array()).map(|arr| {
                    arr.iter()
                        .filter_map(|item| {
                            let order_index = item.get("order_index").and_then(|v| v.as_i64()).unwrap_or(0) as i32;
                            let acceptable_answers = item.get("acceptable_answers")
                                .and_then(|v| v.as_array())
                                .map(|a| a.iter().filter_map(|s| s.as_str().map(|s| s.to_string())).collect::<Vec<_>>())
                                .unwrap_or_default();
                            Some(EnumerationItemInput { order_index, acceptable_answers })
                        })
                        .collect::<Vec<_>>()
                });

                let request = UpdateQuestionRequest {
                    question_text,
                    points,
                    order_index,
                    is_multi_select,
                    choices,
                    correct_answers,
                    enumeration_items,
                };

                match self.assessment_service.update_question(question_id, request, user_id).await {
                    Ok(_response) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "delete" => {
                let question_id = match op.payload.get("id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid question id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                match self.assessment_service.delete_question(question_id, user_id).await {
                    Ok(_) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            _ => OperationResult {
                id: op.id.clone(),
                entity_type: op.entity_type.clone(),
                operation: op.operation.clone(),
                success: false,
                server_id: None,
                error: Some(format!("Unknown operation for question: {}", op.operation)),
                updated_at: None,
                metadata: None,
            },
        }
    }

    /// Handle assignment operations (create, update, delete)
    async fn handle_assignment_operation(
        &self,
        user_id: Uuid,
        _user_role: &str,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let class_id = match op.payload.get("class_id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid class_id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let title = match op.payload.get("title").and_then(|v| v.as_str()) {
                    Some(t) => t.to_string(),
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing title field".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let instructions = match op.payload.get("instructions").and_then(|v| v.as_str()) {
                    Some(i) => i.to_string(),
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing instructions field".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };
                let total_points = op.payload.get("total_points").and_then(|v| v.as_i64()).unwrap_or(100) as i32;
                let due_at = op.payload.get("due_at").and_then(|v| v.as_str()).map(|s| s.to_string()).unwrap_or_else(|| Utc::now().to_rfc3339());
                let submission_type = op.payload.get("submission_type").and_then(|v| v.as_str()).map(|s| s.to_string()).unwrap_or_else(|| "text".to_string());

                let request = CreateAssignmentRequest {
                    title,
                    instructions,
                    total_points,
                    submission_type,
                    allowed_file_types: None,
                    max_file_size_mb: None,
                    due_at,
                };

                match self.assignment_service.create_assignment(
                    class_id,
                    request,
                    user_id,
                ).await {
                    Ok(response) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: Some(response.id.to_string()),
                        error: None,
                        updated_at: Some(response.updated_at),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "update" => {
                let assignment_id = match op.payload.get("id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid assignment id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let title = op.payload.get("title").and_then(|v| v.as_str()).map(|s| s.to_string());
                let instructions = op.payload.get("instructions").and_then(|v| v.as_str()).map(|s| s.to_string());
                let total_points = op.payload.get("total_points").and_then(|v| v.as_i64()).map(|v| v as i32);
                let due_at = op.payload.get("due_at").and_then(|v| v.as_str()).map(|s| s.to_string());
                let submission_type = op.payload.get("submission_type").and_then(|v| v.as_str()).map(|s| s.to_string());

                let request = UpdateAssignmentRequest {
                    title,
                    instructions,
                    total_points,
                    submission_type,
                    allowed_file_types: None,
                    max_file_size_mb: None,
                    due_at,
                };

                match self.assignment_service.update_assignment(
                    assignment_id,
                    request,
                    user_id,
                ).await {
                    Ok(response) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(response.updated_at),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "delete" => {
                let assignment_id = match op.payload.get("id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid assignment id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                match self.assignment_service.soft_delete(assignment_id, user_id).await {
                    Ok(_) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "publish" => {
                let assignment_id = match op.payload.get("id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid assignment id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                match self.assignment_service.publish_assignment(assignment_id, user_id).await {
                    Ok(_) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            _ => OperationResult {
                id: op.id.clone(),
                entity_type: op.entity_type.clone(),
                operation: op.operation.clone(),
                success: false,
                server_id: None,
                error: Some(format!("Unknown operation: {}", op.operation)),
                updated_at: None,
                metadata: None,
            },
        }
    }

    /// Handle learning material operations (create, update, delete)
    async fn handle_learning_material_operation(
        &self,
        user_id: Uuid,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let class_id = match op.payload.get("class_id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid class_id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let title = match op.payload.get("title").and_then(|v| v.as_str()) {
                    Some(t) => t.to_string(),
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing title field".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let description = op.payload.get("description").and_then(|v| v.as_str()).map(|s| s.to_string());
                let content_text = op.payload.get("content_text").and_then(|v| v.as_str()).map(|s| s.to_string());

                let request = CreateMaterialRequest {
                    title,
                    description,
                    content_text,
                };

                match self.material_service.create_material(
                    class_id,
                    request,
                    user_id,
                ).await {
                    Ok(response) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: Some(response.id.to_string()),
                        error: None,
                        updated_at: Some(response.updated_at),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "update" => {
                let material_id = match op.payload.get("id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid material id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let title = op.payload.get("title").and_then(|v| v.as_str()).map(|s| s.to_string());
                let description = op.payload.get("description").and_then(|v| v.as_str()).map(|s| s.to_string());
                let content_text = op.payload.get("content_text").and_then(|v| v.as_str()).map(|s| s.to_string());

                let request = UpdateMaterialRequest {
                    title,
                    description,
                    content_text,
                };

                match self.material_service.update_material(
                    material_id,
                    request,
                    user_id,
                ).await {
                    Ok(response) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(response.updated_at),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "delete" => {
                let material_id = match op.payload.get("id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid material id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                match self.material_service.soft_delete(material_id, user_id).await {
                    Ok(_) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            _ => OperationResult {
                id: op.id.clone(),
                entity_type: op.entity_type.clone(),
                operation: op.operation.clone(),
                success: false,
                server_id: None,
                error: Some(format!("Unknown operation: {}", op.operation)),
                updated_at: None,
                metadata: None,
            },
        }
    }

    /// Handle assessment submission operations (student-only)
    async fn handle_assessment_submission_operation(
        &self,
        user_id: Uuid,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let assessment_id = op.payload.get("assessment_id")
                    .and_then(|v| v.as_str())
                    .and_then(|s| Uuid::parse_str(s).ok());

                match assessment_id {
                    None => OperationResult {
                        id: op.id.clone(), entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(), success: false, server_id: None,
                        error: Some("Missing assessment_id".to_string()), updated_at: None, metadata: None,
                    },
                    Some(assessment_id) => {
                        match self.assessment_service.start_assessment(assessment_id, user_id).await {
                            Ok(submission) => OperationResult {
                                id: op.id.clone(), entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(), success: true,
                                server_id: Some(submission.submission_id.to_string()),
                                error: None, updated_at: None, metadata: None,
                            },
                            Err(e) => OperationResult {
                                id: op.id.clone(), entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(), success: false,
                                server_id: None, error: Some(e.to_string()), updated_at: None, metadata: None,
                            },
                        }
                    }
                }
            }
            "save_answers" => {
                // Try to get submission_id first, fall back to local_id if needed
                let submission_id = match op.payload.get("submission_id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => Some(id),
                    None => {
                        // Try local_id as fallback for offline submissions
                        op.payload.get("local_id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok())
                    }
                };

                let submission_id = match submission_id {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid submission_id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let request = match op.payload.get("answers") {
                    Some(answers_val) => match serde_json::from_value::<SaveAnswersRequest>(serde_json::json!({ "answers": answers_val })) {
                        Ok(req) => req,
                        Err(_) => {
                            return OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some("Invalid answers format".to_string()),
                                updated_at: None,
                                metadata: None,
                            };
                        }
                    },
                    None => SaveAnswersRequest { answers: vec![] },
                };

                match self.assessment_service.save_answers(submission_id, request, user_id).await {
                    Ok(_) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "submit" => {
                let submission_id = match op.payload.get("submission_id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid submission_id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                match self.assessment_service.submit_assessment(submission_id, user_id).await {
                    Ok(_) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "override_answer" => {
                let answer_id = match op.payload.get("answer_id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid answer_id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let is_correct = op.payload.get("is_correct").and_then(|v| v.as_bool()).unwrap_or(false);

                use crate::schema::assessment_schema::OverrideAnswerRequest;
                let request = OverrideAnswerRequest { is_correct };

                match self.assessment_service.override_answer(answer_id, request, user_id).await {
                    Ok(_) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            _ => OperationResult {
                id: op.id.clone(),
                entity_type: op.entity_type.clone(),
                operation: op.operation.clone(),
                success: false,
                server_id: None,
                error: Some(format!("Unknown operation: {}", op.operation)),
                updated_at: None,
                metadata: None,
            },
        }
    }

    /// Handle assignment submission operations (student-only)
    async fn handle_assignment_submission_operation(
        &self,
        user_id: Uuid,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "create" => {
                let assignment_id = match op.payload.get("assignment_id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid assignment_id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                match self.assignment_service.create_or_get_submission(assignment_id, user_id, None).await {
                    Ok(response) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: Some(response.id.to_string()),
                        error: None,
                        updated_at: Some(response.updated_at),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "submit" => {
                let submission_id = match op.payload.get("submission_id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid submission_id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                match self.assignment_service.submit_assignment(submission_id, user_id).await {
                    Ok(_) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "grade" => {
                let submission_id = match op.payload.get("id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid submission_id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let score = match op.payload.get("score").and_then(|v| v.as_i64()) {
                    Some(s) => s as i32,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing score field".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let feedback = op.payload.get("feedback").and_then(|v| v.as_str()).map(|s| s.to_string());

                use crate::schema::assignment_schema::GradeSubmissionRequest;
                let request = GradeSubmissionRequest { score, feedback };

                match self.assignment_service.grade_submission(submission_id, request, user_id).await {
                    Ok(_) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            "update" => {
                let submission_id = match op.payload.get("id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid submission_id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                let action = op.payload.get("action").and_then(|v| v.as_str()).unwrap_or("");

                if action == "return" {
                    match self.assignment_service.return_submission(submission_id, user_id).await {
                        Ok(_) => OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: true,
                            server_id: None,
                            error: None,
                            updated_at: Some(Utc::now().to_rfc3339()),
                            metadata: None,
                        },
                        Err(e) => OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some(e.to_string()),
                            updated_at: None,
                            metadata: None,
                        },
                    }
                } else {
                    OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(format!("Unknown update action: {}", action)),
                        updated_at: None,
                        metadata: None,
                    }
                }
            }
            _ => OperationResult {
                id: op.id.clone(),
                entity_type: op.entity_type.clone(),
                operation: op.operation.clone(),
                success: false,
                server_id: None,
                error: Some(format!("Unknown operation: {}", op.operation)),
                updated_at: None,
                metadata: None,
            },
        }
    }

    /// Handle submission file operations (delete only)
    async fn handle_submission_file_operation(
        &self,
        user_id: Uuid,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "delete" => {
                let file_id = match op.payload.get("file_id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid file_id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                match self.assignment_service.delete_file(file_id, user_id).await {
                    Ok(_) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            _ => OperationResult {
                id: op.id.clone(),
                entity_type: op.entity_type.clone(),
                operation: op.operation.clone(),
                success: false,
                server_id: None,
                error: Some(format!("Unknown operation for submission_file: {}", op.operation)),
                updated_at: None,
                metadata: None,
            },
        }
    }

    /// Handle material file operations (delete only)
    async fn handle_material_file_operation(
        &self,
        user_id: Uuid,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        match op.operation.as_str() {
            "delete" => {
                let file_id = match op.payload.get("file_id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
                    Some(id) => id,
                    None => {
                        return OperationResult {
                            id: op.id.clone(),
                            entity_type: op.entity_type.clone(),
                            operation: op.operation.clone(),
                            success: false,
                            server_id: None,
                            error: Some("Missing or invalid file_id".to_string()),
                            updated_at: None,
                            metadata: None,
                        };
                    }
                };

                match self.material_service.delete_file(file_id, user_id).await {
                    Ok(_) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: true,
                        server_id: None,
                        error: None,
                        updated_at: Some(Utc::now().to_rfc3339()),
                        metadata: None,
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
                        metadata: None,
                    },
                }
            }
            _ => OperationResult {
                id: op.id.clone(),
                entity_type: op.entity_type.clone(),
                operation: op.operation.clone(),
                success: false,
                server_id: None,
                error: Some(format!("Unknown operation for material_file: {}", op.operation)),
                updated_at: None,
                metadata: None,
            },
        }
    }

    /// Handle activity log operations (read-only fetch)
    /// Activity logs are synced as part of the manifest fetch, not pushed via this endpoint
    async fn handle_activity_log_operation(
        &self,
        _user_id: Uuid,
        op: &SyncQueueEntry,
    ) -> OperationResult {
        // Activity logs are read-only and should only be fetched via the manifest/fetch endpoints
        // If somehow an operation reaches here, return success to prevent sync loop failures
        // but note that the actual activity log data comes from the fetch endpoint
        OperationResult {
            id: op.id.clone(),
            entity_type: op.entity_type.clone(),
            operation: op.operation.clone(),
            success: true,
            server_id: None,
            error: None,
            updated_at: Some(Utc::now().to_rfc3339()),
            metadata: None,
        }
    }
}
