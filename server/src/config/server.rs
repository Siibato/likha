use std::env;

use uuid::Uuid;

use crate::utils::{net, validators::Validator};

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
    pub file_encryption_key: String,
    pub allowed_origins: Vec<String>,
    pub max_body_size_bytes: u64,
    pub redis_url: String,
    pub cache_enabled: bool,
    pub cache_ttl_list_seconds: u64,
    pub cache_ttl_detail_seconds: u64,
    pub cache_ttl_static_seconds: u64,
    pub peer_url: Option<String>,
    pub node_id: String,
    pub node_ip: String,
    pub mesh_group_id: Option<String>,
    pub replication_secret: Option<String>,
    pub replication_interval_seconds: u64,
    pub discovery_multicast_addr: String,
    pub discovery_beacon_interval_seconds: u64,
    pub discovery_peer_ttl_seconds: u64,
}

impl ServerConfig {
    pub fn from_env() -> Self {
        let db_encryption_key = env::var("DB_ENCRYPTION_KEY")
            .expect("DB_ENCRYPTION_KEY must be set in .env file");

        Validator::validate_encryption_key(&db_encryption_key)
            .unwrap_or_else(|e| panic!("Invalid DB_ENCRYPTION_KEY: {}", e));

        let file_encryption_key = env::var("FILE_ENCRYPTION_KEY")
            .expect("FILE_ENCRYPTION_KEY must be set in .env file");

        Validator::validate_encryption_key(&file_encryption_key)
            .unwrap_or_else(|e| panic!("Invalid FILE_ENCRYPTION_KEY: {}", e));

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
                .expect("SCHOOL_CODE must be set in .env file"),
            db_encryption_key,
            file_encryption_key,
            allowed_origins,
            max_body_size_bytes,
            redis_url: env::var("REDIS_URL").unwrap_or_else(|_| "redis://localhost:6379".to_string()),
            cache_enabled: env::var("CACHE_ENABLED")
                .unwrap_or_else(|_| "true".to_string())
                .parse::<bool>()
                .unwrap_or(true),
            cache_ttl_list_seconds: env::var("CACHE_TTL_LIST_SECONDS")
                .unwrap_or_else(|_| "300".to_string())
                .parse()
                .unwrap_or(300),
            cache_ttl_detail_seconds: env::var("CACHE_TTL_DETAIL_SECONDS")
                .unwrap_or_else(|_| "120".to_string())
                .parse()
                .unwrap_or(120),
            cache_ttl_static_seconds: env::var("CACHE_TTL_STATIC_SECONDS")
                .unwrap_or_else(|_| "3600".to_string())
                .parse()
                .unwrap_or(3600),
            peer_url: env::var("PEER_URL").ok().filter(|s| !s.is_empty()),
            node_id: env::var("NODE_ID").unwrap_or_else(|_| Uuid::new_v4().to_string()),
            node_ip: env::var("NODE_IP").unwrap_or_else(|_| net::detect_local_ip()),
            mesh_group_id: env::var("MESH_GROUP_ID").ok().filter(|s| !s.is_empty()),
            replication_secret: env::var("REPLICATION_SECRET").ok().filter(|s| !s.is_empty()),
            replication_interval_seconds: env::var("REPLICATION_INTERVAL_SECONDS")
                .unwrap_or_else(|_| "30".to_string())
                .parse()
                .unwrap_or(30),
            discovery_multicast_addr: env::var("DISCOVERY_MULTICAST_ADDR")
                .unwrap_or_else(|_| "239.255.42.99:9999".to_string()),
            discovery_beacon_interval_seconds: env::var("DISCOVERY_BEACON_INTERVAL_SECONDS")
                .unwrap_or_else(|_| "5".to_string())
                .parse()
                .unwrap_or(5),
            discovery_peer_ttl_seconds: env::var("DISCOVERY_PEER_TTL_SECONDS")
                .unwrap_or_else(|_| "30".to_string())
                .parse()
                .unwrap_or(30),
        }
    }
}
