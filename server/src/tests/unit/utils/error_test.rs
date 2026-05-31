//! Tests for error types and formatting

use crate::utils::error::AppError;

#[test]
fn test_internal_server_error_display() {
    let err = AppError::InternalServerError("database failed".to_string());
    assert!(err.to_string().contains("Internal Server Error"));
    assert!(err.to_string().contains("database failed"));
}

#[test]
fn test_bad_request_display() {
    let err = AppError::BadRequest("invalid input".to_string());
    assert!(err.to_string().contains("Bad Request"));
    assert!(err.to_string().contains("invalid input"));
}

#[test]
fn test_not_found_display() {
    let err = AppError::NotFound("user not found".to_string());
    assert!(err.to_string().contains("Not Found"));
    assert!(err.to_string().contains("user not found"));
}

#[test]
fn test_unauthorized_display() {
    let err = AppError::Unauthorized("token expired".to_string());
    assert!(err.to_string().contains("Unauthorized"));
    assert!(err.to_string().contains("token expired"));
}

#[test]
fn test_forbidden_display() {
    let err = AppError::Forbidden("access denied".to_string());
    assert!(err.to_string().contains("Forbidden"));
    assert!(err.to_string().contains("access denied"));
}

#[test]
fn test_conflict_display() {
    let err = AppError::Conflict("duplicate entry".to_string());
    assert!(err.to_string().contains("Conflict"));
    assert!(err.to_string().contains("duplicate entry"));
}

#[test]
fn test_too_many_requests_display() {
    let err = AppError::TooManyRequests(60);
    assert!(err.to_string().contains("Too Many Requests"));
    assert!(err.to_string().contains("60 seconds remaining"));
}

#[test]
fn test_invalid_credentials_display() {
    let err = AppError::InvalidCredentials("wrong password".to_string(), 3);
    assert!(err.to_string().contains("Invalid Credentials"));
    assert!(err.to_string().contains("wrong password"));
}
