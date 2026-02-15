use serde::{Deserialize, Serialize};
use uuid::Uuid;

use super::auth_schema::UserResponse;

// ===== REQUEST SCHEMAS =====

#[derive(Debug, Deserialize)]
pub struct CreateClassRequest {
    pub title: String,
    pub description: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateClassRequest {
    pub title: Option<String>,
    pub description: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct AddStudentRequest {
    pub student_id: Uuid,
}

#[derive(Debug, Deserialize)]
pub struct SearchStudentsQuery {
    pub q: Option<String>,
}

// ===== RESPONSE SCHEMAS =====

#[derive(Debug, Serialize)]
pub struct ClassResponse {
    pub id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub teacher_id: Uuid,
    pub teacher_username: String,
    pub teacher_full_name: String,
    pub is_archived: bool,
    pub student_count: usize,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Serialize)]
pub struct ClassDetailResponse {
    pub id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub teacher_id: Uuid,
    pub is_archived: bool,
    pub students: Vec<EnrollmentResponse>,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Serialize)]
pub struct EnrollmentResponse {
    pub id: Uuid,
    pub student: UserResponse,
    pub enrolled_at: String,
}

#[derive(Debug, Serialize)]
pub struct ClassListResponse {
    pub classes: Vec<ClassResponse>,
}

// ===== METADATA SCHEMAS =====

#[derive(Debug, Serialize)]
pub struct ClassMetadataResponse {
    pub last_modified: String,
    pub record_count: usize,
    pub etag: String,
}
