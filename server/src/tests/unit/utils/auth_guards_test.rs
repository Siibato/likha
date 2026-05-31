//! Tests for authorization guard functions

use crate::middleware::auth_middleware::AuthUser;
use crate::utils::auth_guards::{
    require_admin, require_student, require_teacher, require_teacher_or_admin,
};

fn create_auth_user(role: &str) -> AuthUser {
    AuthUser {
        user_id: uuid::Uuid::new_v4(),
        role: role.to_string(),
    }
}

#[test]
fn test_require_teacher_with_teacher() {
    let user = create_auth_user("teacher");
    assert!(require_teacher(&user).is_ok());
}

#[test]
fn test_require_teacher_with_student() {
    let user = create_auth_user("student");
    assert!(require_teacher(&user).is_err());
}

#[test]
fn test_require_teacher_with_admin() {
    let user = create_auth_user("admin");
    assert!(require_teacher(&user).is_err());
}

#[test]
fn test_require_student_with_student() {
    let user = create_auth_user("student");
    assert!(require_student(&user).is_ok());
}

#[test]
fn test_require_student_with_teacher() {
    let user = create_auth_user("teacher");
    assert!(require_student(&user).is_err());
}

#[test]
fn test_require_student_with_admin() {
    let user = create_auth_user("admin");
    assert!(require_student(&user).is_err());
}

#[test]
fn test_require_teacher_or_admin_with_teacher() {
    let user = create_auth_user("teacher");
    assert!(require_teacher_or_admin(&user).is_ok());
}

#[test]
fn test_require_teacher_or_admin_with_admin() {
    let user = create_auth_user("admin");
    assert!(require_teacher_or_admin(&user).is_ok());
}

#[test]
fn test_require_teacher_or_admin_with_student() {
    let user = create_auth_user("student");
    assert!(require_teacher_or_admin(&user).is_err());
}

#[test]
fn test_require_admin_with_admin() {
    let user = create_auth_user("admin");
    assert!(require_admin(&user).is_ok());
}

#[test]
fn test_require_admin_with_teacher() {
    let user = create_auth_user("teacher");
    assert!(require_admin(&user).is_err());
}

#[test]
fn test_require_admin_with_student() {
    let user = create_auth_user("student");
    assert!(require_admin(&user).is_err());
}
