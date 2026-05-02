use std::env;

use crate::utils::validators::Validator;

#[derive(Debug, Clone)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
    pub database_url: String,
    pub jwt_secret: String,
    pub jwt_expiration: i64,
    pub file_storage_path: String,
    pub school_code: String,
    pub db_encryption_key: String,
    pub allowed_origins: Vec<String>,
    pub max_body_size_bytes: u64,
}

impl ServerConfig {
    pub fn from_env() -> Self {
        let db_encryption_key = env::var("DB_ENCRYPTION_KEY")
            .expect("DB_ENCRYPTION_KEY must be set in .env file");

        Validator::validate_encryption_key(&db_encryption_key)
            .unwrap_or_else(|e| panic!("Invalid DB_ENCRYPTION_KEY: {}", e));

        let max_body_size_bytes = env::var("MAX_BODY_SIZE_MB")
            .unwrap_or_else(|_| "55".to_string())
            .parse::<u64>()
            .expect("MAX_BODY_SIZE_MB must be a valid number")
            * 1024
            * 1024;

        let allowed_origins = env::var("ALLOWED_ORIGINS")
            .unwrap_or_default()
            .split(',')
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .map(String::from)
            .collect();

        Self {
            host: env::var("HOST").unwrap_or_else(|_| "0.0.0.0".to_string()),
            port: env::var("PORT")
                .unwrap_or_else(|_| "8080".to_string())
                .parse()
                .expect("PORT must be a valid number"),
            database_url: env::var("DATABASE_URL")
                .unwrap_or_else(|_| "sqlite://./data/lms.db?mode=rwc".to_string()),
            jwt_secret: env::var("JWT_SECRET").expect("JWT_SECRET must be set in .env file"),
            jwt_expiration: env::var("JWT_EXPIRATION")
                .unwrap_or_else(|_| "86400".to_string())
                .parse()
                .expect("JWT_EXPIRATION must be a valid number"),
            file_storage_path: env::var("FILE_STORAGE_PATH")
                .unwrap_or_else(|_| "./uploads".to_string()),
            school_code: env::var("SCHOOL_CODE")
                .unwrap_or_else(|_| "CHANGE_ME".to_string()),
            db_encryption_key,
            allowed_origins,
            max_body_size_bytes,
        }
    }
}
