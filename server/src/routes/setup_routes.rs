use axum::{routing::get, Router};
use std::sync::Arc;

use crate::handlers::setup_handler;
use crate::services::setup_service::SetupService;

pub fn routes(setup_service: Arc<SetupService>) -> Router {
    Router::new()
        // Public — students verify school code + check school info
        .route("/setup/verify", get(setup_handler::verify_code))
        .route("/setup/info", get(setup_handler::get_school_info))
        // Admin — QR code generation
        .route("/admin/setup/qr", get(setup_handler::get_qr_code))
        // Admin — school code management
        .route(
            "/admin/setup/code",
            get(setup_handler::get_school_code).put(setup_handler::update_school_code),
        )
        // Admin — school settings (name, region, division, year)
        .route(
            "/admin/setup/school-settings",
            get(setup_handler::get_school_settings).put(setup_handler::update_school_settings),
        )
        .with_state(setup_service)
}
