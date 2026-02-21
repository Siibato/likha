use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::{Deserialize, Serialize};
use std::fmt;

#[derive(Debug, Serialize, Deserialize)]
pub struct ErrorResponse {
    pub error: String,
    pub message: String,
    pub status_code: u16,
}

#[derive(Debug)]
pub enum AppError {
    InternalServerError(String),
    BadRequest(String),
    NotFound(String),
    Unauthorized(String),
    Forbidden(String),
    Conflict(String),
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            AppError::InternalServerError(msg) => write!(f, "Internal Server Error: {}", msg),
            AppError::BadRequest(msg) => write!(f, "Bad Request: {}", msg),
            AppError::NotFound(msg) => write!(f, "Not Found: {}", msg),
            AppError::Unauthorized(msg) => write!(f, "Unauthorized: {}", msg),
            AppError::Forbidden(msg) => write!(f, "Forbidden: {}", msg),
            AppError::Conflict(msg) => write!(f, "Conflict: {}", msg),
        }
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, error_message, message) = match self {
            AppError::InternalServerError(msg) => {
                (StatusCode::INTERNAL_SERVER_ERROR, "Internal Server Error", msg)
            }
            AppError::BadRequest(msg) => (StatusCode::BAD_REQUEST, "Bad Request", msg),
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, "Not Found", msg),
            AppError::Unauthorized(msg) => (StatusCode::UNAUTHORIZED, "Unauthorized", msg),
            AppError::Forbidden(msg) => (StatusCode::FORBIDDEN, "Forbidden", msg),
            AppError::Conflict(msg) => (StatusCode::CONFLICT, "Conflict", msg),
        };

        let body = Json(ErrorResponse {
            error: error_message.to_string(),
            message,
            status_code: status.as_u16(),
        });

        (status, body).into_response()
    }
}

pub type AppResult<T> = Result<T, AppError>;
