use uuid::Uuid;

use crate::utils::jwt::JwtService;

use super::test_app::TEST_JWT_SECRET;

pub fn make_teacher_token(user_id: Uuid, username: &str) -> String {
    make_token(user_id, username, "teacher")
}

pub fn make_admin_token(user_id: Uuid, username: &str) -> String {
    make_token(user_id, username, "admin")
}

pub fn make_student_token(user_id: Uuid, username: &str) -> String {
    make_token(user_id, username, "student")
}

/// A well-formed JWT signed with a different secret — will fail middleware verification.
pub fn wrong_secret_token() -> String {
    JwtService::new("not_the_real_secret".to_string(), 3600)
        .generate_token(Uuid::new_v4(), "ghost", "teacher")
        .unwrap()
}

fn make_token(user_id: Uuid, username: &str, role: &str) -> String {
    JwtService::new(TEST_JWT_SECRET.to_string(), 3600)
        .generate_token(user_id, username, role)
        .expect("test token creation failed")
}
