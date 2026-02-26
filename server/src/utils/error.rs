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
    #[serde(skip_serializing_if = "Option::is_none")]
    pub attempts_remaining: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub remaining_seconds: Option<i64>,
}

#[derive(Debug)]
pub enum AppError {
    InternalServerError(String),
    BadRequest(String),
    NotFound(String),
    Unauthorized(String),
    Forbidden(String),
    Conflict(String),
    TooManyRequests(i64),              // remaining_seconds
    InvalidCredentials(String, i32),   // (message, attempts_remaining)
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
            AppError::TooManyRequests(secs) => write!(f, "Too Many Requests: {} seconds remaining", secs),
            AppError::InvalidCredentials(msg, _) => write!(f, "Invalid Credentials: {}", msg),
        }
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, error_message, message, attempts_remaining, remaining_seconds) = match self {
            AppError::InternalServerError(msg) => {
                (StatusCode::INTERNAL_SERVER_ERROR, "Internal Server Error", msg, None, None)
            }
            AppError::BadRequest(msg) => (StatusCode::BAD_REQUEST, "Bad Request", msg, None, None),
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, "Not Found", msg, None, None),
            AppError::Unauthorized(msg) => (StatusCode::UNAUTHORIZED, "Unauthorized", msg, None, None),
            AppError::Forbidden(msg) => (StatusCode::FORBIDDEN, "Forbidden", msg, None, None),
            AppError::Conflict(msg) => (StatusCode::CONFLICT, "Conflict", msg, None, None),
            AppError::TooManyRequests(secs) => (
                StatusCode::TOO_MANY_REQUESTS,
                "Too Many Requests",
                "Too many failed login attempts. Please try again later.".to_string(),
                None,
                Some(secs),
            ),
            AppError::InvalidCredentials(msg, attempts) => (
                StatusCode::UNAUTHORIZED,
                "Invalid Credentials",
                msg,
                Some(attempts),
                None,
            ),
        };

        let body = Json(ErrorResponse {
            error: error_message.to_string(),
            message,
            status_code: status.as_u16(),
            attempts_remaining,
            remaining_seconds,
        });

        (status, body).into_response()
    }
}

pub type AppResult<T> = Result<T, AppError>;
