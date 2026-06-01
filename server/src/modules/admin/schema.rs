use serde::{Deserialize, Serialize};
use uuid::Uuid;
use crate::modules::auth::schema::UserResponse;

// ===== REQUEST SCHEMAS =====

#[derive(Debug, Deserialize)]
pub struct CreateAccountRequest {
    pub username: String,
    pub full_name: String,
    pub role: String,
}

#[derive(Debug, Deserialize)]
pub struct UpdateAccountRequest {
    pub full_name: Option<String>,
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
