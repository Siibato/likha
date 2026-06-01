use axum::{
    routing::{get, post},
    Router,
};
use std::sync::Arc;

use crate::modules::auth::handler;
use crate::modules::auth::service::AuthService;

pub fn routes(auth_service: Arc<AuthService>) -> Router {
    Router::new()
        // Public endpoints
        .route("/auth/check-username", post(handler::check_username))
        .route("/auth/activate", post(handler::activate))
        .route("/auth/login", post(handler::login))
        .route("/auth/refresh", post(handler::refresh_token))
        // Authenticated endpoints
        .route("/auth/me", get(handler::get_current_user))
        .route("/auth/logout", post(handler::logout))
        .with_state(auth_service)
}
