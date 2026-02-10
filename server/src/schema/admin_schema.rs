use serde::Serialize;
use uuid::Uuid;

use super::auth_schema::UserResponse;

#[derive(Debug, Serialize)]
pub struct AccountListResponse {
    pub accounts: Vec<UserResponse>,
    pub total: usize,
}

#[derive(Debug, Serialize)]
pub struct ActivityLogResponse {
    pub id: Uuid,
    pub user_id: Uuid,
    pub action: String,
    pub performed_by: Option<Uuid>,
    pub details: Option<String>,
    pub created_at: String,
}

#[derive(Debug, Serialize)]
pub struct ActivityLogListResponse {
    pub logs: Vec<ActivityLogResponse>,
}
