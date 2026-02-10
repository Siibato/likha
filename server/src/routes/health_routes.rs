use crate::handlers::health_handler;
use axum::{Router, routing::get};

pub fn routes() -> Router {
    Router::new()
        .route("/health", get(health_handler::health_check))
        .route("/health/ready", get(health_handler::readiness_check))
}
