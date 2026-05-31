use axum::{
    routing::{delete, get, post, put},
    Router,
};
use std::sync::Arc;

use crate::handlers::admin_handler;
use crate::modules::auth::service::AuthService;

pub fn routes(auth_service: Arc<AuthService>) -> Router {
    Router::new()
        // Admin account endpoints
        .route(
            "/auth/accounts",
            post(admin_handler::create_account).get(admin_handler::get_all_accounts),
        )
        .route("/auth/accounts/reset", post(admin_handler::reset_account))
        .route("/auth/accounts/lock", post(admin_handler::lock_account))
        .route(
            "/auth/accounts/{id}",
            get(admin_handler::get_account)
                .put(admin_handler::update_account)
                .delete(admin_handler::delete_account),
        )
        .route(
            "/auth/accounts/{id}/logs",
            get(admin_handler::get_activity_logs),
        )
        .route("/students/search", get(admin_handler::search_students))
        .with_state(auth_service)
}
