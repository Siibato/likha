use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::utils::{AppError, AppResult};

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,      // User ID
    pub username: String,
    pub role: String,
    pub exp: i64,         // Expiration time
    pub iat: i64,         // Issued at
}

pub struct JwtService {
    secret: String,
    pub expiration: i64,
}

impl JwtService {
    pub fn new(secret: String, expiration: i64) -> Self {
        Self { secret, expiration }
    }

    pub fn generate_token(&self, user_id: Uuid, username: &str, role: &str) -> AppResult<String> {
        let now = Utc::now();
        let expires_at = now + Duration::seconds(self.expiration);

        let claims = Claims {
            sub: user_id.to_string(),
            username: username.to_string(),
            role: role.to_string(),
            exp: expires_at.timestamp(),
            iat: now.timestamp(),
        };

        encode(
            &Header::default(),
            &claims,
            &EncodingKey::from_secret(self.secret.as_bytes()),
        )
        .map_err(|e| AppError::InternalServerError(format!("Failed to generate token: {}", e)))
    }

    pub fn verify_token(&self, token: &str) -> AppResult<Claims> {
        decode::<Claims>(
            token,
            &DecodingKey::from_secret(self.secret.as_bytes()),
            &Validation::default(),
        )
        .map(|data| data.claims)
        .map_err(|_| AppError::Unauthorized("Invalid or expired token".to_string()))
    }

    pub fn generate_refresh_token(&self) -> String {
        use uuid::Uuid;
        Uuid::new_v4().to_string()
    }
}