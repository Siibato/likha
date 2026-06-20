use serde::Serialize;
use serde_json::Value;

// ===== PUSH SYNC SCHEMAS (re-export from old services) =====
pub use crate::modules::sync::service_operations::push::sync_push_service::{SyncQueueEntry, OperationResult, PushResponse};

// ===== DELTA SYNC SCHEMAS (re-export from old services) =====
pub use crate::modules::sync::service_operations::delta::sync_delta_service::DeltaRequest;

#[derive(Debug, Clone, Serialize)]
pub struct EntityDeltas {
    pub updated: Vec<Value>,
    pub deleted: Vec<String>,
}

#[derive(Debug, Clone, Serialize)]
pub struct DeltaPayload {
    pub classes: EntityDeltas,
    pub enrollments: EntityDeltas,
    pub assessments: EntityDeltas,
    pub questions: EntityDeltas,
    pub assessment_submissions: EntityDeltas,
    pub assignments: EntityDeltas,
    pub assignment_submissions: EntityDeltas,
    pub learning_materials: EntityDeltas,
    pub grade_configs: EntityDeltas,
    pub grade_items: EntityDeltas,
    pub grade_scores: EntityDeltas,
    pub period_grades: EntityDeltas,
    pub table_of_specifications: EntityDeltas,
    pub tos_competencies: EntityDeltas,
    pub learner_details: EntityDeltas,
    pub attendance_records: EntityDeltas,
    pub core_values_records: EntityDeltas,
    pub student_school_history: EntityDeltas,
    pub previous_school_subjects: EntityDeltas,
    pub previous_school_attendance: EntityDeltas,
}

#[derive(Debug, Clone, Serialize)]
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

// ===== FULL SYNC SCHEMAS (re-export from old services) =====
pub use crate::modules::sync::service_operations::full::sync_full_service::{FullSyncRequest, FullSyncResponse};

// ===== CONFLICT RESOLUTION SCHEMAS =====

pub use crate::modules::sync::service_operations::conflict_service::{ConflictResolutionRequest, ConflictResolutionResponse};
