use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ===== REQUEST SCHEMAS =====

#[derive(Debug, Deserialize)]
pub struct CreateAccountRequest {
    pub username: String,
    pub full_name: String,
    pub role: String,
}

#[derive(Debug, Deserialize)]
pub struct ActivateAccountRequest {
    pub username: String,
    pub password: String,
    pub confirm_password: String,
}

#[derive(Debug, Deserialize)]
pub struct CheckUsernameRequest {
    pub username: String,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub username: String,
    pub password: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub device_id: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct RefreshTokenRequest {
    pub refresh_token: String,
}

#[derive(Debug, Deserialize)]
pub struct ResetAccountRequest {
    pub user_id: Uuid,
}

#[derive(Debug, Deserialize)]
pub struct LockAccountRequest {
    pub user_id: Uuid,
    pub locked: bool,
}

#[derive(Debug, Deserialize)]
pub struct ResetPasswordRequest {
    pub user_id: Uuid,
}

#[derive(Debug, Deserialize)]
pub struct UpdateAccountRequest {
    pub username: Option<String>,
    pub full_name: Option<String>,
    pub role: Option<String>,
}

// ===== RESPONSE SCHEMAS =====

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub token_type: String,
    pub expires_in: i64,
    pub user: UserResponse,
}

#[derive(Debug, Serialize, Clone)]
pub struct UserResponse {
    pub id: Uuid,
    pub username: String,
    pub full_name: String,
    pub role: String,
    pub account_status: String,
    pub is_active: bool,
    pub activated_at: Option<String>,
    pub created_at: String,
}

#[derive(Debug, Serialize)]
pub struct CheckUsernameResponse {
    pub username: String,
    pub account_status: String,
    pub full_name: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct MessageResponse {
    pub message: String,
}
