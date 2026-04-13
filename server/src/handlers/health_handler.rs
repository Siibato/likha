use axum::{http::StatusCode, response::IntoResponse};
use chrono::Utc;
use serde::{Deserialize, Serialize};

use crate::schema::common::success_response;

#[derive(Debug, Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    pub timestamp: String,
    pub version: String,
    pub service: String,
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
