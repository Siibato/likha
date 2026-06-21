use axum::{
    routing::{get, post},
    Router,
};
use std::sync::Arc;

use crate::modules::admin::handler;
use crate::modules::admin::service::AdminService;

pub fn routes(admin_service: Arc<AdminService>) -> Router {
    Router::new()
        // Admin account endpoints
        .route(
            "/auth/accounts",
            post(handler::create_account).get(handler::get_all_accounts),
        )
        .route("/auth/accounts/reset", post(handler::reset_account))
        .route("/auth/accounts/lock", post(handler::lock_account))
        .route(
            "/auth/accounts/{id}",
            get(handler::get_account)
                .put(handler::update_account)
                .delete(handler::delete_account),
        )
        .route(
            "/auth/accounts/{id}/logs",
            get(handler::get_activity_logs),
        )
        .route(
            "/auth/accounts/{id}/details",
            get(handler::get_account_details).put(handler::upsert_account_details),
        )
        .route("/students/search", get(handler::search_students))
        .with_state(admin_service)
}
