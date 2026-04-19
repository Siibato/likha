use axum::{http::StatusCode, response::IntoResponse};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};

use crate::schema::common::success_response;

#[derive(Debug, Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    pub timestamp: String,
    pub version: String,
    pub service: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DatabaseIdResponse {
    pub database_id: String,
}

pub async fn health_check() -> impl IntoResponse {
    let response = HealthResponse {
        status: "healthy".to_string(),
        timestamp: Utc::now().to_rfc3339(),
        version: env!("CARGO_PKG_VERSION").to_string(),
        service: "Likha API".to_string(),
    };

    success_response(response, StatusCode::OK).into_response()
}

pub async fn readiness_check() -> impl IntoResponse {
    let response = HealthResponse {
        status: "ready".to_string(),
        timestamp: Utc::now().to_rfc3339(),
        version: env!("CARGO_PKG_VERSION").to_string(),
        service: "Likha API".to_string(),
    };

    success_response(response, StatusCode::OK).into_response()
}

pub async fn get_database_id() -> impl IntoResponse {
    // Generate a consistent database ID based on the database path
    // This will change if the database file changes, which is useful for cache invalidation
    let db_path = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "sqlite:likha.db".to_string());

    let mut hasher = DefaultHasher::new();
    db_path.hash(&mut hasher);
    let hash = hasher.finish();

    let response = DatabaseIdResponse {
        database_id: format!("{:x}", hash),
    };

    success_response(response, StatusCode::OK).into_response()
}
