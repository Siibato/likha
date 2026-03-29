use axum::{extract::State, http::StatusCode, response::IntoResponse};
use std::sync::Arc;

use crate::middleware::auth_middleware::AuthUser;
use crate::schema::common::success_response;
use crate::services::setup_service::SetupService;
use crate::utils::auth_guards::require_admin;

pub async fn get_qr_code(
    State(setup_service): State<Arc<SetupService>>,
    auth_user: AuthUser,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }
    match setup_service.generate_qr_code() {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_short_code(
    State(setup_service): State<Arc<SetupService>>,
    auth_user: AuthUser,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }
    match setup_service.generate_short_code() {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}
