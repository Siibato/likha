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

    // === Content Field Validation ===

    /// Validate required title field (trim, check empty, check max length 200).
    pub fn validate_title(title: &str) -> AppResult<String> {
        let t = title.trim().to_string();
        if t.is_empty() {
            return Err(AppError::BadRequest("Title is required".to_string()));
        }
        if t.len() > 200 {
            return Err(AppError::BadRequest(
                "Title must be at most 200 characters".to_string(),
            ));
        }
        Ok(t)
    }

    /// Validate optional title field for updates.
    pub fn validate_optional_title(title: Option<String>) -> AppResult<Option<String>> {
        match title {
            Some(t) => Ok(Some(Validator::validate_title(&t)?)),
            None => Ok(None),
        }
    }

    /// Validate required instructions field (trim, check empty, check max length 10000).
    pub fn validate_instructions(instructions: &str) -> AppResult<String> {
        let i = instructions.trim().to_string();
        if i.is_empty() {
            return Err(AppError::BadRequest("Instructions are required".to_string()));
        }
        if i.len() > 10000 {
            return Err(AppError::BadRequest(
                "Instructions must be at most 10000 characters".to_string(),
            ));
        }
        Ok(i)
    }

    /// Validate optional instructions field for updates.
    pub fn validate_optional_instructions(instructions: Option<String>) -> AppResult<Option<String>> {
        match instructions {
            Some(i) => Ok(Some(Validator::validate_instructions(&i)?)),
            None => Ok(None),
        }
    }

    /// Validate required points field (range 1-1000).
    pub fn validate_points(points: i32) -> AppResult<()> {
        if points < 1 || points > 1000 {
            return Err(AppError::BadRequest(
                "Total points must be between 1 and 1000".to_string(),
            ));
        }
        Ok(())
    }

    /// Validate optional points field for updates.
    pub fn validate_optional_points(points: Option<i32>) -> AppResult<()> {
        if let Some(p) = points {
            Validator::validate_points(p)?;
        }
        Ok(())
    }

    
    /// Validate the DB encryption key at startup.
    /// Panics if invalid — this is intentional (misconfiguration must not start the server).
    /// Allows hex, base64, alphanumeric, +, /, =, -, _ characters; rejects SQL-unsafe chars.
    pub fn validate_encryption_key(key: &str) -> Result<(), String> {
        if key.len() < 32 {
            return Err(format!(
                "DB_ENCRYPTION_KEY must be at least 32 characters (got {})",
                key.len()
            ));
        }

        for ch in key.chars() {
            if matches!(ch, '\'' | '"' | '\\' | ';' | '\n' | '\r' | '\0') {
                return Err(format!(
                    "DB_ENCRYPTION_KEY contains unsafe character '{}'. Use hex or base64 encoding.",
                    ch
                ));
            }
        }

        Ok(())
    }

    /// Validate max file size in MB (range 1-50).
    pub fn validate_max_file_size(size_mb: i32) -> AppResult<()> {
        if size_mb < 1 || size_mb > 50 {
            return Err(AppError::BadRequest(
                "Max file size must be between 1 and 50 MB".to_string(),
            ));
        }
        Ok(())
    }

    /// Validate optional max file size field.
    pub fn validate_optional_max_file_size(size_mb: Option<i32>) -> AppResult<()> {
        if let Some(size) = size_mb {
            Validator::validate_max_file_size(size)?;
        }
        Ok(())
    }
}
