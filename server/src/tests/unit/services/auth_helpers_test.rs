use uuid::Uuid;
use crate::services::auth::AuthService;

fn make_user(account_status: &str) -> ::entity::users::Model {
    ::entity::users::Model {
        id: Uuid::new_v4(),
        username: "testuser".to_string(),
        full_name: "Test User".to_string(),
        password_hash: Some("hash".to_string()),
        role: "teacher".to_string(),
        account_status: account_status.to_string(),
        activated_at: None,
        created_at: chrono::Utc::now().naive_utc(),
        updated_at: chrono::Utc::now().naive_utc(),
        deleted_at: None,
    }
}

#[test]
fn test_user_to_response_active_status_is_active_true() {
    let user = make_user("active");
    let response = AuthService::user_to_response(&user);
    assert!(response.is_active);
}

#[test]
fn test_user_to_response_locked_status_is_active_false() {
    let user = make_user("locked");
    let response = AuthService::user_to_response(&user);
    assert!(!response.is_active);
}

#[test]
fn test_user_to_response_deactivated_status_is_active_false() {
    let user = make_user("deactivated");
    let response = AuthService::user_to_response(&user);
    assert!(!response.is_active);
}

#[test]
fn test_user_to_response_pending_activation_is_active_true() {
    let user = make_user("pending_activation");
    let response = AuthService::user_to_response(&user);
    assert!(response.is_active);
}

#[test]
fn test_user_to_response_fields_mapped_correctly() {
    let id = Uuid::new_v4();
    let mut user = make_user("active");
    user.id = id;
    user.username = "john_doe".to_string();
    user.full_name = "John Doe".to_string();
    user.role = "student".to_string();
    user.account_status = "active".to_string();

    let response = AuthService::user_to_response(&user);
    assert_eq!(response.id, id);
    assert_eq!(response.username, "john_doe");
    assert_eq!(response.full_name, "John Doe");
    assert_eq!(response.role, "student");
    assert_eq!(response.account_status, "active");
}

#[test]
fn test_user_to_response_activated_at_none_maps_to_none() {
    let mut user = make_user("active");
    user.activated_at = None;
    let response = AuthService::user_to_response(&user);
    assert!(response.activated_at.is_none());
}

#[test]
fn test_user_to_response_activated_at_some_maps_to_some_string() {
    let mut user = make_user("active");
    user.activated_at = Some(chrono::Utc::now().naive_utc());
    let response = AuthService::user_to_response(&user);
    assert!(response.activated_at.is_some());
}
