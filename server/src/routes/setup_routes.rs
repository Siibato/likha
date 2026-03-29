use axum::{routing::get, Router};
use std::sync::Arc;

use crate::handlers::setup_handler;
use crate::services::setup_service::SetupService;

pub fn routes(setup_service: Arc<SetupService>) -> Router {
    Router::new()
        .route("/admin/setup/qr", get(setup_handler::get_qr_code))
        .route("/admin/setup/code", get(setup_handler::get_short_code))
        .with_state(setup_service)
}
