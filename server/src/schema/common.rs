use axum::{http::StatusCode, Json};
use serde::Serialize;

#[derive(Debug, Serialize)]
pub struct ApiResponse<T> {
    pub success: bool,
    pub status_code: u16,
    pub data: Option<T>,
    pub error: Option<String>,
}

impl<T> ApiResponse<T> {
    pub fn success(data: T, status_code: StatusCode) -> Self {
        Self {
            success: true,
            status_code: status_code.as_u16(),
            data: Some(data),
            error: None,
        }
    }
}

/// Helper function to create a success response with the correct status code.
/// Eliminates duplication by ensuring the status code is only specified once.
pub fn success_response<T: Serialize>(
    data: T,
    status: StatusCode,
) -> (StatusCode, Json<ApiResponse<T>>) {
    (status, Json(ApiResponse::success(data, status)))
}