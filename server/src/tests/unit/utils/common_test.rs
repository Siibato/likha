//! Tests for common schema utilities

use crate::schema::common::{success_response, ApiResponse};
use axum::http::StatusCode;

#[test]
fn test_api_response_success() {
    let response: ApiResponse<i32> = ApiResponse::success(42, StatusCode::OK);
    assert!(response.success);
    assert_eq!(response.status_code, 200);
    assert_eq!(response.data, Some(42));
    assert!(response.error.is_none());
}

#[test]
fn test_api_response_success_different_status() {
    let response: ApiResponse<String> = ApiResponse::success("created".to_string(), StatusCode::CREATED);
    assert!(response.success);
    assert_eq!(response.status_code, 201);
}

#[test]
fn test_success_response_helper() {
    let (status, _json) = success_response("test data", StatusCode::OK);
    assert_eq!(status, StatusCode::OK);
}

#[test]
fn test_success_response_created() {
    let (status, _json) = success_response(123, StatusCode::CREATED);
    assert_eq!(status, StatusCode::CREATED);
}

#[test]
fn test_success_response_accepted() {
    let (status, _json) = success_response("processing", StatusCode::ACCEPTED);
    assert_eq!(status, StatusCode::ACCEPTED);
}
