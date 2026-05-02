use std::env;

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
}

impl ServerConfig {
    pub fn from_env() -> Self {
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
            db_encryption_key: env::var("DB_ENCRYPTION_KEY")
                .expect("DB_ENCRYPTION_KEY must be set in .env file"),
        }
    }
}
