use axum::{routing::get, Router};

use crate::modules::health::handler;

pub fn routes() -> Router {
    Router::new()
        .route("/health", get(handler::health_check))
        .route("/health/ready", get(handler::readiness_check))
        .route("/database-id", get(handler::get_database_id))
}
