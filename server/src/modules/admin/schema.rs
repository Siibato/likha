use crate::modules::auth::schema::UserResponse;
use crate::modules::student_records::schema::LearnerDetailsResponse;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ===== REQUEST SCHEMAS =====

#[derive(Debug, Deserialize)]
pub struct CreateAccountRequest {
    pub username: String,
    pub first_name: String,
    pub last_name: String,
    pub role: String,
    pub learner_details: Option<LearnerDetailsPayload>,
    pub teacher_details: Option<TeacherDetailsPayload>,
}

#[derive(Debug, Deserialize)]
pub struct LearnerDetailsPayload {
    pub lrn: Option<String>,
    pub sex: Option<String>,
    pub track_strand: Option<String>,
    pub curriculum: Option<String>,
    pub birthdate: Option<String>,
    pub birthplace: Option<String>,
    pub home_address: Option<String>,
    pub father_name: Option<String>,
    pub father_contact: Option<String>,
    pub mother_name: Option<String>,
    pub mother_contact: Option<String>,
    pub guardian_name: Option<String>,
    pub guardian_contact: Option<String>,
    pub date_admitted: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct TeacherDetailsPayload {
    pub license_id: Option<String>,
    pub rank: Option<String>,
    pub position: Option<String>,
    pub sex: Option<String>,
    pub birthdate: Option<String>,
    pub home_address: Option<String>,
    pub date_hired: Option<String>,
    pub education_level: Option<String>,
    pub specialization: Option<String>,
    pub contact_number: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateAccountDetailsRequest {
    pub learner_details: Option<LearnerDetailsPayload>,
    pub teacher_details: Option<TeacherDetailsPayload>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateAccountRequest {
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub role: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct ResetAccountRequest {
    pub user_id: Uuid,
}

#[derive(Debug, Deserialize)]
pub struct LockAccountRequest {
    pub user_id: Uuid,
    pub locked: bool,
    pub reason: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct SearchStudentsQuery {
    pub q: Option<String>,
}

// ===== RESPONSE SCHEMAS =====

#[derive(Debug, Serialize)]
pub struct MessageResponse {
    pub message: String,
}

#[derive(Debug, Serialize)]
pub struct AccountListResponse {
    pub accounts: Vec<UserResponse>,
}

#[derive(Debug, Serialize)]
pub struct ActivityLogResponse {
    pub id: Uuid,
    pub user_id: Uuid,
    pub action: String,
    pub details: Option<String>,
    pub created_at: String,
}

#[derive(Debug, Serialize)]
pub struct ActivityLogListResponse {
    pub logs: Vec<ActivityLogResponse>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TeacherDetailsResponse {
    pub id: String,
    pub user_id: String,
    pub license_id: Option<String>,
    pub rank: Option<String>,
    pub position: Option<String>,
    pub sex: Option<String>,
    pub birthdate: Option<String>,
    pub home_address: Option<String>,
    pub date_hired: Option<String>,
    pub education_level: Option<String>,
    pub specialization: Option<String>,
    pub contact_number: Option<String>,
}

impl From<::entity::teacher_details::Model> for TeacherDetailsResponse {
    fn from(m: ::entity::teacher_details::Model) -> Self {
        Self {
            id: m.id.to_string(),
            user_id: m.user_id.to_string(),
            license_id: m.license_id,
            rank: m.rank,
            position: m.position,
            sex: m.sex,
            birthdate: m.birthdate.map(|d| d.to_string()),
            home_address: m.home_address,
            date_hired: m.date_hired.map(|d| d.to_string()),
            education_level: m.education_level,
            specialization: m.specialization,
            contact_number: m.contact_number,
        }
    }
}

#[derive(Debug, Serialize)]
pub struct AccountDetailResponse {
    pub user: UserResponse,
    pub learner_details: Option<LearnerDetailsResponse>,
    pub teacher_details: Option<TeacherDetailsResponse>,
}
