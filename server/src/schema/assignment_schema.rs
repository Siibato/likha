use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ===== REQUEST SCHEMAS =====

#[derive(Debug, Deserialize)]
pub struct CreateAssignmentRequest {
    pub title: String,
    pub instructions: String,
    pub total_points: i32,
    pub submission_type: String,
    pub allowed_file_types: Option<String>,
    pub max_file_size_mb: Option<i32>,
    pub due_at: String,
}

#[derive(Debug, Deserialize)]
pub struct UpdateAssignmentRequest {
    pub title: Option<String>,
    pub instructions: Option<String>,
    pub total_points: Option<i32>,
    pub submission_type: Option<String>,
    pub allowed_file_types: Option<String>,
    pub max_file_size_mb: Option<i32>,
    pub due_at: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct GradeSubmissionRequest {
    pub score: i32,
    pub feedback: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct SubmitTextRequest {
    pub text_content: Option<String>,
}

// ===== RESPONSE SCHEMAS =====

#[derive(Debug, Serialize)]
pub struct AssignmentResponse {
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: String,
    pub instructions: String,
    pub total_points: i32,
    pub submission_type: String,
    pub allowed_file_types: Option<String>,
    pub max_file_size_mb: Option<i32>,
    pub due_at: String,
    pub is_published: bool,
    pub submission_count: usize,
    pub graded_count: usize,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Serialize)]
pub struct AssignmentListResponse {
    pub assignments: Vec<AssignmentResponse>,
}

#[derive(Debug, Serialize)]
pub struct StudentAssignmentListItem {
    pub id: Uuid,
    pub title: String,
    pub total_points: i32,
    pub submission_type: String,
    pub due_at: String,
    pub is_published: bool,
    pub submission_status: Option<String>,
    pub score: Option<i32>,
}

#[derive(Debug, Serialize)]
pub struct StudentAssignmentListResponse {
    pub assignments: Vec<StudentAssignmentListItem>,
}

#[derive(Debug, Serialize)]
pub struct AssignmentSubmissionResponse {
    pub id: Uuid,
    pub assignment_id: Uuid,
    pub student_id: Uuid,
    pub student_name: String,
    pub status: String,
    pub text_content: Option<String>,
    pub submitted_at: Option<String>,
    pub is_late: bool,
    pub score: Option<i32>,
    pub feedback: Option<String>,
    pub graded_at: Option<String>,
    pub files: Vec<FileMetadataResponse>,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Serialize)]
pub struct SubmissionListResponse {
    pub submissions: Vec<SubmissionListItem>,
}

#[derive(Debug, Serialize)]
pub struct SubmissionListItem {
    pub id: Uuid,
    pub student_id: Uuid,
    pub student_name: String,
    pub status: String,
    pub submitted_at: Option<String>,
    pub is_late: bool,
    pub score: Option<i32>,
}

#[derive(Debug, Serialize)]
pub struct FileMetadataResponse {
    pub id: Uuid,
    pub file_name: String,
    pub file_type: String,
    pub file_size: i64,
    pub uploaded_at: String,
}
