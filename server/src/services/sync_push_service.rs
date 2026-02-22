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
#[derive(Debug, Clone, serde::Serialize)]
pub struct OperationResult {
    pub id: String,              // Matches SyncQueueEntry.id
    pub entity_type: String,
    pub operation: String,
    pub success: bool,
    pub server_id: Option<String>, // For creates
    pub error: Option<String>,
    pub updated_at: Option<String>,
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
}

impl SyncPushService {
    pub fn new(
        entitlement_service: Arc<EntitlementService>,
        class_service: Arc<ClassService>,
        assessment_service: Arc<AssessmentService>,
        assignment_service: Arc<AssignmentService>,
        material_service: Arc<LearningMaterialService>,
        auth_service: Arc<AuthService>,
    ) -> Self {
        Self {
            entitlement_service,
            class_service,
            assessment_service,
            assignment_service,
            material_service,
            auth_service,
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
            let result = self.process_single_operation(user_id, user_role, &op).await;
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
            };
        }

        // Route to appropriate handler
        match op.entity_type.as_str() {
            "class" => self.handle_class_operation(user_id, op).await,
            "admin_user" => self.handle_admin_user_operation(user_id, op).await,
            "assessment" => self.handle_assessment_operation(user_id, user_role, op).await,
            "assignment" => self.handle_assignment_operation(user_id, user_role, op).await,
            "learning_material" => self.handle_learning_material_operation(user_id, op).await,
            "assessment_submission" => {
                self.handle_assessment_submission_operation(user_id, op).await
            }
            "assignment_submission" => {
                self.handle_assignment_submission_operation(user_id, op).await
            }
            _ => OperationResult {
                id: op.id.clone(),
                entity_type: op.entity_type.clone(),
                operation: op.operation.clone(),
                success: false,
                server_id: None,
                error: Some(format!("Unknown entity type: {}", op.entity_type)),
                updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
                            },
                            Err(e) => OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some(e.to_string()),
                                updated_at: None,
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
                            },
                            Err(e) => OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some(e.to_string()),
                                updated_at: None,
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
                            },
                            Err(e) => OperationResult {
                                id: op.id.clone(),
                                entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(),
                                success: false,
                                server_id: None,
                                error: Some(e.to_string()),
                                updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
                        error: Some("Missing assessment_id".to_string()), updated_at: None,
                    },
                    Some(assessment_id) => {
                        match self.assessment_service.start_assessment(assessment_id, user_id).await {
                            Ok(submission) => OperationResult {
                                id: op.id.clone(), entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(), success: true,
                                server_id: Some(submission.submission_id.to_string()),
                                error: None, updated_at: None,
                            },
                            Err(e) => OperationResult {
                                id: op.id.clone(), entity_type: op.entity_type.clone(),
                                operation: op.operation.clone(), success: false,
                                server_id: None, error: Some(e.to_string()), updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
                    },
                    Err(e) => OperationResult {
                        id: op.id.clone(),
                        entity_type: op.entity_type.clone(),
                        operation: op.operation.clone(),
                        success: false,
                        server_id: None,
                        error: Some(e.to_string()),
                        updated_at: None,
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
            },
        }
    }
}
