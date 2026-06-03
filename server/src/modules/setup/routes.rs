use axum::{routing::get, Router};
use std::sync::Arc;

use crate::modules::setup::handler;
use crate::modules::setup::service::SetupService;

pub fn routes(setup_service: Arc<SetupService>) -> Router {
    Router::new()
        // Public — students verify school code + check school info
        .route("/setup/verify", get(handler::verify_code))
        .route("/setup/info", get(handler::get_school_info))
        // Admin — QR code generation
        .route("/admin/setup/qr", get(handler::get_qr_code))
        // Admin — school code management
        .route(
            "/admin/setup/code",
            get(handler::get_school_code).put(handler::update_school_code),
        )
        // Admin — school settings (name, region, division, year)
        .route(
            "/admin/setup/school-settings",
            get(handler::get_school_settings).put(handler::update_school_settings),
        )
        .with_state(setup_service)
}
