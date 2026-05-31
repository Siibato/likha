use crate::schema::auth_schema::{
    ActivateAccountRequest, CheckUsernameRequest, CreateAccountRequest, LoginRequest,
    UserResponse,
};
use uuid::Uuid;

// ===== LoginRequest deserialization =====

#[test]
fn test_login_request_deserializes_with_device_id() {
    let json = r#"{"username":"alice","password":"secret","device_id":"dev-123"}"#;
    let req: LoginRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.username, "alice");
    assert_eq!(req.password, "secret");
    assert_eq!(req.device_id.as_deref(), Some("dev-123"));
}

#[test]
fn test_login_request_deserializes_without_device_id() {
    let json = r#"{"username":"alice","password":"secret"}"#;
    let req: LoginRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.username, "alice");
    assert!(req.device_id.is_none());
}

#[test]
fn test_login_request_missing_required_field_fails() {
    let json = r#"{"username":"alice"}"#; // missing password
    let result: Result<LoginRequest, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

// ===== CreateAccountRequest deserialization =====

#[test]
fn test_create_account_request_deserializes() {
    let json = r#"{"username":"bob","full_name":"Bob Smith","role":"teacher"}"#;
    let req: CreateAccountRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.username, "bob");
    assert_eq!(req.full_name, "Bob Smith");
    assert_eq!(req.role, "teacher");
}

// ===== ActivateAccountRequest deserialization =====

#[test]
fn test_activate_account_request_deserializes() {
    let json = r#"{"username":"carol","password":"pw123","confirm_password":"pw123"}"#;
    let req: ActivateAccountRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.username, "carol");
    assert_eq!(req.password, "pw123");
    assert_eq!(req.confirm_password, "pw123");
}

// ===== CheckUsernameRequest deserialization =====

#[test]
fn test_check_username_request_deserializes() {
    let json = r#"{"username":"dave"}"#;
    let req: CheckUsernameRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.username, "dave");
}

// ===== UserResponse serialization =====

#[test]
fn test_user_response_serializes_with_is_active_true() {
    let resp = UserResponse {
        id: Uuid::new_v4(),
        username: "eve".to_string(),
        full_name: "Eve Adams".to_string(),
        role: "student".to_string(),
        account_status: "active".to_string(),
        is_active: true,
        activated_at: None,
        created_at: "2024-01-01T00:00:00".to_string(),
    };
    let json = serde_json::to_string(&resp).unwrap();
    assert!(json.contains("\"is_active\":true"));
    assert!(json.contains("\"username\":\"eve\""));
}

#[test]
fn test_user_response_serializes_with_is_active_false_for_locked() {
    let resp = UserResponse {
        id: Uuid::new_v4(),
        username: "frank".to_string(),
        full_name: "Frank Lee".to_string(),
        role: "teacher".to_string(),
        account_status: "locked".to_string(),
        is_active: false,
        activated_at: None,
        created_at: "2024-01-01T00:00:00".to_string(),
    };
    let json = serde_json::to_string(&resp).unwrap();
    assert!(json.contains("\"is_active\":false"));
    assert!(json.contains("\"account_status\":\"locked\""));
}

#[test]
fn test_user_response_activated_at_none_serializes_as_null() {
    let resp = UserResponse {
        id: Uuid::new_v4(),
        username: "grace".to_string(),
        full_name: "Grace Hopper".to_string(),
        role: "admin".to_string(),
        account_status: "active".to_string(),
        is_active: true,
        activated_at: None,
        created_at: "2024-01-01T00:00:00".to_string(),
    };
    let json = serde_json::to_string(&resp).unwrap();
    assert!(json.contains("\"activated_at\":null"));
}
