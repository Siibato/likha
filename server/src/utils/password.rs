use bcrypt::{hash, verify, DEFAULT_COST};
use sha2::{Sha256, Digest};

use crate::utils::{AppError, AppResult};

pub struct PasswordService;

impl PasswordService {
    pub fn hash_password(password: &str) -> AppResult<String> {
        hash(password, DEFAULT_COST)
            .map_err(|e| AppError::InternalServerError(format!("Failed to hash password: {}", e)))
    }

    pub fn verify_password(password: &str, hash: &str) -> AppResult<bool> {
        verify(password, hash)
            .map_err(|e| AppError::InternalServerError(format!("Failed to verify password: {}", e)))
    }

    /// Deterministic SHA-256 hash for token lookup (not for passwords).
    pub fn hash_token(token: &str) -> String {
        let mut hasher = Sha256::new();
        hasher.update(token.as_bytes());
        hex::encode(hasher.finalize())
    }
}