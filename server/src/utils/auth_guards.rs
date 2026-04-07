use axum::response::{IntoResponse, Response};

use crate::middleware::auth_middleware::AuthUser;
use crate::utils::error::AppError;

pub fn require_teacher(auth_user: &AuthUser) -> Result<(), Response> {
    if auth_user.role != "teacher" {
        return Err(AppError::Forbidden("Teacher access required".to_string()).into_response());
    }
    Ok(())
}

pub fn require_student(auth_user: &AuthUser) -> Result<(), Response> {
    if auth_user.role != "student" {
        return Err(AppError::Forbidden("Student access required".to_string()).into_response());
    }
    Ok(())
}

pub fn require_teacher_or_admin(auth_user: &AuthUser) -> Result<(), Response> {
    if auth_user.role != "teacher" && auth_user.role != "admin" {
        return Err(
            AppError::Forbidden("Teacher or admin access required".to_string()).into_response(),
        );
    }
    Ok(())
}

pub fn require_admin(auth_user: &AuthUser) -> Result<(), AppError> {
    if auth_user.role != "admin" {
        return Err(AppError::Forbidden("Admin access required".to_string()));
    }
    Ok(())
}
