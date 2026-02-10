use regex::Regex;

use crate::utils::{AppError, AppResult};

pub struct Validator;

impl Validator {
    pub fn validate_username(username: &str) -> AppResult<()> {
        if username.len() < 3 {
            return Err(AppError::BadRequest(
                "Username must be at least 3 characters".to_string(),
            ));
        }

        if username.len() > 50 {
            return Err(AppError::BadRequest(
                "Username must not exceed 50 characters".to_string(),
            ));
        }

        let username_regex = Regex::new(r"^[a-zA-Z0-9_-]+$")
            .map_err(|e| AppError::InternalServerError(format!("Regex error: {}", e)))?;

        if username_regex.is_match(username) {
            Ok(())
        } else {
            Err(AppError::BadRequest(
                "Username can only contain letters, numbers, underscores, and hyphens".to_string(),
            ))
        }
    }

    pub fn validate_password(password: &str) -> AppResult<()> {
        if password.len() < 8 {
            return Err(AppError::BadRequest(
                "Password must be at least 8 characters".to_string(),
            ));
        }

        if password.len() > 100 {
            return Err(AppError::BadRequest(
                "Password must not exceed 100 characters".to_string(),
            ));
        }

        Ok(())
    }

    pub fn validate_role(role: &str) -> AppResult<()> {
        match role {
            "teacher" | "student" | "admin" => Ok(()),
            _ => Err(AppError::BadRequest(
                "Role must be 'teacher', 'student', or 'admin'".to_string(),
            )),
        }
    }
}
