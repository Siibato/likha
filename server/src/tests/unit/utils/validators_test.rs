//! Tests for input validators
//!
//! Tests validation logic for:
//! - Usernames (format, length)
//! - Passwords (length constraints)
//! - Roles (enum validation)
//! - Title and instructions (content validation)
//! - Points and file sizes (range validation)

use crate::utils::validators::Validator;

// ===== Username Tests =====

#[test]
fn test_validate_username_too_short() {
    let result = Validator::validate_username("ab");
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("at least 3 characters"));
}

#[test]
fn test_validate_username_min_length() {
    let result = Validator::validate_username("abc");
    assert!(result.is_ok());
}

#[test]
fn test_validate_username_too_long() {
    let result = Validator::validate_username(&"a".repeat(51));
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("not exceed 50 characters"));
}

#[test]
fn test_validate_username_max_length() {
    let result = Validator::validate_username(&"a".repeat(50));
    assert!(result.is_ok());
}

#[test]
fn test_validate_username_valid() {
    assert!(Validator::validate_username("teacher01").is_ok());
    assert!(Validator::validate_username("student_01").is_ok());
    assert!(Validator::validate_username("john-doe").is_ok());
    assert!(Validator::validate_username("user123").is_ok());
}

#[test]
fn test_validate_username_invalid_chars() {
    let result = Validator::validate_username("teacher@01");
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("letters, numbers, underscores, and hyphens"));
}

#[test]
fn test_validate_username_spaces() {
    let result = Validator::validate_username("teacher 01");
    assert!(result.is_err());
}

// ===== Password Tests =====

#[test]
fn test_validate_password_too_short() {
    let result = Validator::validate_password("short");
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("at least 8 characters"));
}

#[test]
fn test_validate_password_min_length() {
    let result = Validator::validate_password("password");
    assert!(result.is_ok());
}

#[test]
fn test_validate_password_too_long() {
    let result = Validator::validate_password(&"a".repeat(101));
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("not exceed 100 characters"));
}

#[test]
fn test_validate_password_max_length() {
    let result = Validator::validate_password(&"a".repeat(100));
    assert!(result.is_ok());
}

#[test]
fn test_validate_password_valid() {
    assert!(Validator::validate_password("SecurePass123!").is_ok());
}

// ===== Role Tests =====

#[test]
fn test_validate_role_teacher() {
    assert!(Validator::validate_role("teacher").is_ok());
}

#[test]
fn test_validate_role_student() {
    assert!(Validator::validate_role("student").is_ok());
}

#[test]
fn test_validate_role_admin() {
    assert!(Validator::validate_role("admin").is_ok());
}

#[test]
fn test_validate_role_invalid() {
    let result = Validator::validate_role("superuser");
    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("teacher") || err_msg.contains("student") || err_msg.contains("admin"));
}

#[test]
fn test_validate_role_case_sensitive() {
    let result = Validator::validate_role("Teacher");
    assert!(result.is_err()); // Should be lowercase
}

// ===== Title Tests =====

#[test]
fn test_validate_title_empty() {
    let result = Validator::validate_title("");
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("Title is required"));
}

#[test]
fn test_validate_title_whitespace_only() {
    let result = Validator::validate_title("   ");
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("Title is required"));
}

#[test]
fn test_validate_title_too_long() {
    let result = Validator::validate_title(&"a".repeat(201));
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("at most 200 characters"));
}

#[test]
fn test_validate_title_max_length() {
    let result = Validator::validate_title(&"a".repeat(200));
    assert!(result.is_ok());
}

#[test]
fn test_validate_title_trims_whitespace() {
    let result = Validator::validate_title("  Test Title  ");
    assert!(result.is_ok());
    assert_eq!(result.unwrap(), "Test Title");
}

#[test]
fn test_validate_title_valid() {
    assert!(Validator::validate_title("Assignment 1").is_ok());
    assert!(Validator::validate_title("Quiz: Chapter 3").is_ok());
}

#[test]
fn test_validate_optional_title_some_valid() {
    let result = Validator::validate_optional_title(Some("Valid Title".to_string()));
    assert!(result.is_ok());
}

#[test]
fn test_validate_optional_title_some_invalid() {
    let result = Validator::validate_optional_title(Some("".to_string()));
    assert!(result.is_err());
}

#[test]
fn test_validate_optional_title_none() {
    let result = Validator::validate_optional_title(None);
    assert!(result.is_ok());
    assert_eq!(result.unwrap(), None);
}

// ===== Instructions Tests =====

#[test]
fn test_validate_instructions_empty() {
    let result = Validator::validate_instructions("");
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("Instructions are required"));
}

#[test]
fn test_validate_instructions_too_long() {
    let result = Validator::validate_instructions(&"a".repeat(10001));
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("at most 10000 characters"));
}

#[test]
fn test_validate_instructions_max_length() {
    let result = Validator::validate_instructions(&"a".repeat(10000));
    assert!(result.is_ok());
}

#[test]
fn test_validate_instructions_valid() {
    assert!(Validator::validate_instructions("Complete the exercises").is_ok());
}

#[test]
fn test_validate_optional_instructions_none() {
    let result = Validator::validate_optional_instructions(None);
    assert!(result.is_ok());
}

// ===== Points Tests =====

#[test]
fn test_validate_points_too_low() {
    let result = Validator::validate_points(0);
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("between 1 and 1000"));
}

#[test]
fn test_validate_points_min() {
    assert!(Validator::validate_points(1).is_ok());
}

#[test]
fn test_validate_points_max() {
    assert!(Validator::validate_points(1000).is_ok());
}

#[test]
fn test_validate_points_too_high() {
    let result = Validator::validate_points(1001);
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("between 1 and 1000"));
}

#[test]
fn test_validate_points_valid() {
    assert!(Validator::validate_points(100).is_ok());
    assert!(Validator::validate_points(50).is_ok());
}

#[test]
fn test_validate_optional_points_none() {
    let result = Validator::validate_optional_points(None);
    assert!(result.is_ok());
}

#[test]
fn test_validate_optional_points_some_valid() {
    let result = Validator::validate_optional_points(Some(100));
    assert!(result.is_ok());
}

#[test]
fn test_validate_optional_points_some_invalid() {
    let result = Validator::validate_optional_points(Some(0));
    assert!(result.is_err());
}

// ===== Max File Size Tests =====

#[test]
fn test_validate_max_file_size_too_low() {
    let result = Validator::validate_max_file_size(0);
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("between 1 and 50"));
}

#[test]
fn test_validate_max_file_size_min() {
    assert!(Validator::validate_max_file_size(1).is_ok());
}

#[test]
fn test_validate_max_file_size_max() {
    assert!(Validator::validate_max_file_size(50).is_ok());
}

#[test]
fn test_validate_max_file_size_too_high() {
    let result = Validator::validate_max_file_size(51);
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("between 1 and 50"));
}

#[test]
fn test_validate_optional_max_file_size_none() {
    let result = Validator::validate_optional_max_file_size(None);
    assert!(result.is_ok());
}
