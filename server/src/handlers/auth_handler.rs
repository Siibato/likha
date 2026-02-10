use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use std::sync::Arc;

use crate::schema::auth_schema::{
    ActivateAccountRequest, CheckUsernameRequest, LoginRequest, MessageResponse, RefreshTokenRequest,
};
use crate::schema::common::ApiResponse;
use crate::services::auth_service::AuthService;
use crate::middleware::auth_middleware::AuthUser;

pub async fn check_username(
    State(auth_service): State<Arc<AuthService>>,
    Json(request): Json<CheckUsernameRequest>,
) -> impl IntoResponse {
    match auth_service.check_username(request).await {
        Ok(response) => (
            StatusCode::OK,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn activate(
    State(auth_service): State<Arc<AuthService>>,
    Json(request): Json<ActivateAccountRequest>,
) -> impl IntoResponse {
    match auth_service.activate_account(request).await {
        Ok(response) => (
            StatusCode::OK,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn login(
    State(auth_service): State<Arc<AuthService>>,
    Json(request): Json<LoginRequest>,
) -> impl IntoResponse {
    match auth_service.login(request).await {
        Ok(response) => (
            StatusCode::OK,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn refresh_token(
    State(auth_service): State<Arc<AuthService>>,
    Json(request): Json<RefreshTokenRequest>,
) -> impl IntoResponse {
    match auth_service.refresh_token(&request.refresh_token).await {
        Ok(response) => (
            StatusCode::OK,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_current_user(
    State(auth_service): State<Arc<AuthService>>,
    auth_user: AuthUser,
) -> impl IntoResponse {
    match auth_service.get_current_user(auth_user.user_id).await {
        Ok(user) => (
            StatusCode::OK,
            Json(ApiResponse::success(user)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn logout(
    State(auth_service): State<Arc<AuthService>>,
    Json(request): Json<RefreshTokenRequest>,
) -> impl IntoResponse {
    match auth_service.logout(&request.refresh_token).await {
        Ok(_) => (
            StatusCode::OK,
            Json(ApiResponse::success(MessageResponse {
                message: "Logged out successfully".to_string(),
            })),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}
