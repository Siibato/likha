use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::modules::auth::schema::UserResponse;

// ===== REQUEST SCHEMAS =====

#[derive(Debug, Deserialize)]
pub struct CreateClassRequest {
    pub title: String,
    pub description: Option<String>,
    pub teacher_id: Option<Uuid>,
    pub is_advisory: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateClassRequest {
    pub title: Option<String>,
    pub description: Option<String>,
    pub teacher_id: Option<Uuid>,
    pub is_advisory: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct AddStudentRequest {
    pub student_id: Uuid,
}

// ===== RESPONSE SCHEMAS =====

#[derive(Debug, Serialize, Deserialize)]
pub struct ClassResponse {
    pub id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub teacher_id: Uuid,
    pub teacher_username: String,
    pub teacher_full_name: String,
    pub is_archived: bool,
    pub is_advisory: bool,
    pub student_count: usize,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ClassDetailResponse {
    pub id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub teacher_id: Uuid,
    pub is_archived: bool,
    pub is_advisory: bool,
    pub students: Vec<EnrollmentResponse>,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct EnrollmentResponse {
    pub id: Uuid,
    pub student: UserResponse,
    pub joined_at: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ClassListResponse {
    pub classes: Vec<ClassResponse>,
}

// ===== METADATA SCHEMAS =====

#[derive(Debug, Serialize, Deserialize)]
pub struct ClassMetadataResponse {
    pub last_modified: String,
    pub record_count: usize,
    pub etag: String,
}
