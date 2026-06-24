use axum::{
    extract::{ConnectInfo, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use std::net::SocketAddr;
use std::sync::Arc;

use crate::middleware::auth_middleware::AuthUser;
use crate::modules::auth::schema::{
    ActivateAccountRequest, CheckUsernameRequest, LoginRequest, MessageResponse,
    RefreshTokenRequest,
};
use crate::modules::auth::service::AuthService;
use crate::utils::response::success_response;

pub async fn check_username(
    State(auth_service): State<Arc<AuthService>>,
    Json(request): Json<CheckUsernameRequest>,
) -> impl IntoResponse {
    match auth_service.check_username(request).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn activate(
    State(auth_service): State<Arc<AuthService>>,
    Json(request): Json<ActivateAccountRequest>,
) -> impl IntoResponse {
    match auth_service.activate_account(request).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn login(
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    State(auth_service): State<Arc<AuthService>>,
    Json(request): Json<LoginRequest>,
) -> impl IntoResponse {
    let ip = addr.ip().to_string();
    match auth_service.login(request, &ip).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn refresh_token(
    State(auth_service): State<Arc<AuthService>>,
    Json(request): Json<RefreshTokenRequest>,
) -> impl IntoResponse {
    match auth_service.refresh_token(&request.refresh_token).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_current_user(
    State(auth_service): State<Arc<AuthService>>,
    auth_user: AuthUser,
) -> impl IntoResponse {
    match auth_service
        .get_current_user_cached(auth_user.user_id)
        .await
    {
        Ok(user) => success_response(user, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn logout(
    State(auth_service): State<Arc<AuthService>>,
    Json(request): Json<RefreshTokenRequest>,
) -> impl IntoResponse {
    match auth_service.logout(&request.refresh_token).await {
        Ok(_) => success_response(
            MessageResponse {
                message: "Logged out successfully".to_string(),
            },
            StatusCode::OK,
        )
        .into_response(),
        Err(e) => e.into_response(),
    }
}
