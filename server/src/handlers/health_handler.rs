use axum::{Json, http::StatusCode};
use chrono::Utc;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    pub timestamp: String,
    pub version: String,
    pub service: String,
}

pub async fn health_check() -> (StatusCode, Json<HealthResponse>) {
    let response = HealthResponse {
        status: "healthy".to_string(),
        timestamp: Utc::now().to_rfc3339(),
        version: env!("CARGO_PKG_VERSION").to_string(),
        service: "Likha API".to_string(),
    };

    (StatusCode::OK, Json(response))
}

pub async fn readiness_check() -> (StatusCode, Json<HealthResponse>) {
    let response = HealthResponse {
        status: "ready".to_string(),
        timestamp: Utc::now().to_rfc3339(),
        version: env!("CARGO_PKG_VERSION").to_string(),
        service: "Likha API".to_string(),
    };

    (StatusCode::OK, Json(response))
}
