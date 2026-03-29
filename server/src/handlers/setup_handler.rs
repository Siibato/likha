use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use std::sync::Arc;

use crate::middleware::auth_middleware::AuthUser;
use crate::schema::common::success_response;
use crate::schema::setup_schema::{UpdateCodeRequest, UpdateSchoolSettingsRequest, VerifyQuery};
use crate::services::setup_service::SetupService;
use crate::utils::auth_guards::require_admin;

/// PUBLIC — students verify their school code.
pub async fn verify_code(
    State(setup_service): State<Arc<SetupService>>,
    Query(query): Query<VerifyQuery>,
) -> impl IntoResponse {
    match setup_service.verify_code(&query.code).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

/// PUBLIC — returns school_name (for mobile to check if setup is complete).
pub async fn get_school_info(
    State(setup_service): State<Arc<SetupService>>,
) -> impl IntoResponse {
    match setup_service.get_school_info().await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

/// ADMIN — generates a QR code PNG containing the current school code.
pub async fn get_qr_code(
    State(setup_service): State<Arc<SetupService>>,
    auth_user: AuthUser,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }
    match setup_service.generate_qr_code().await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

/// ADMIN — returns the current school code.
pub async fn get_school_code(
    State(setup_service): State<Arc<SetupService>>,
    auth_user: AuthUser,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }
    match setup_service.get_school_code().await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

/// ADMIN — updates the school code.
pub async fn update_school_code(
    State(setup_service): State<Arc<SetupService>>,
    auth_user: AuthUser,
    Json(request): Json<UpdateCodeRequest>,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }
    match setup_service.update_code(request.code).await {
        Ok(()) => success_response("School code updated", StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

/// ADMIN — returns all school settings.
pub async fn get_school_settings(
    State(setup_service): State<Arc<SetupService>>,
    auth_user: AuthUser,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }
    match setup_service.get_school_settings().await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

/// ADMIN — updates school details (name, region, division, year).
pub async fn update_school_settings(
    State(setup_service): State<Arc<SetupService>>,
    auth_user: AuthUser,
    Json(request): Json<UpdateSchoolSettingsRequest>,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }
    match setup_service.update_school_settings(request).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}
