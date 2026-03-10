use axum::{
    routing::{get, post, put},
    Router,
};
use std::sync::Arc;

use crate::handlers::{admin_handler, auth_handler};
use crate::services::auth::AuthService;

pub fn routes(auth_service: Arc<AuthService>) -> Router {
    Router::new()
        // Public endpoints
        .route("/auth/check-username", post(auth_handler::check_username))
        .route("/auth/activate", post(auth_handler::activate))
        .route("/auth/login", post(auth_handler::login))
        .route("/auth/refresh", post(auth_handler::refresh_token))
        // Authenticated endpoints
        .route("/auth/me", get(auth_handler::get_current_user))
        .route("/auth/logout", post(auth_handler::logout))
        // Admin endpoints
        .route(
            "/auth/accounts",
            post(admin_handler::create_account).get(admin_handler::get_all_accounts),
        )
        .route("/auth/accounts/reset", post(admin_handler::reset_account))
        .route("/auth/accounts/lock", post(admin_handler::lock_account))
        .route(
            "/auth/accounts/{id}",
            get(admin_handler::get_account).put(admin_handler::update_account),
        )
        .route(
            "/auth/accounts/{id}/logs",
            get(admin_handler::get_activity_logs),
        )
        .with_state(auth_service)
}
