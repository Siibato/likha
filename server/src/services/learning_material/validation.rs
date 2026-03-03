use crate::utils::error::{AppError, AppResult};

impl super::LearningMaterialService {
    pub fn validate_title(title: &str) -> AppResult<String> {
        let title = title.trim().to_string();
        if title.is_empty() {
            return Err(AppError::BadRequest("Title is required".to_string()));
        }
        if title.len() > 200 {
            return Err(AppError::BadRequest(
                "Title must be at most 200 characters".to_string(),
            ));
        }
        Ok(title)
    }

    pub fn validate_description(desc: &Option<String>) -> AppResult<Option<String>> {
        if let Some(d) = desc {
            let trimmed = d.trim();
            if trimmed.is_empty() {
                return Ok(None);
            }
            if trimmed.len() > 500 {
                return Err(AppError::BadRequest(
                    "Description must be at most 500 characters".to_string(),
                ));
            }
            Ok(Some(trimmed.to_string()))
        } else {
            Ok(None)
        }
    }

    pub fn validate_content_text(content: &Option<String>) -> AppResult<Option<String>> {
        if let Some(c) = content {
            let trimmed = c.trim();
            if trimmed.is_empty() {
                return Ok(None);
            }
            if trimmed.len() > 50000 {
                return Err(AppError::BadRequest(
                    "Content text must be at most 50000 characters".to_string(),
                ));
            }
            Ok(Some(trimmed.to_string()))
        } else {
            Ok(None)
        }
    }
}