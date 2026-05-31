use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use std::sync::Arc;
use uuid::Uuid;

use crate::modules::auth::schema::{CreateAccountRequest, LockAccountRequest, MessageResponse, ResetAccountRequest, SearchStudentsQuery, UpdateAccountRequest};
use crate::schema::common::success_response;
use crate::modules::auth::service::AuthService;
use crate::middleware::auth_middleware::AuthUser;
use crate::utils::auth_guards::require_admin;

pub async fn create_account(
    State(auth_service): State<Arc<AuthService>>,
    auth_user: AuthUser,
    Json(request): Json<CreateAccountRequest>,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }

    match auth_service.create_account(request, auth_user.user_id, None).await {
        Ok(response) => success_response(response, StatusCode::CREATED).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_all_accounts(
    State(auth_service): State<Arc<AuthService>>,
    auth_user: AuthUser,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }

    match auth_service.get_all_accounts().await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn reset_account(
    State(auth_service): State<Arc<AuthService>>,
    auth_user: AuthUser,
    Json(request): Json<ResetAccountRequest>,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }

    match auth_service.reset_account(request, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn lock_account(
    State(auth_service): State<Arc<AuthService>>,
    auth_user: AuthUser,
    Json(request): Json<LockAccountRequest>,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }

    match auth_service.lock_account(request, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn update_account(
    State(auth_service): State<Arc<AuthService>>,
    auth_user: AuthUser,
    Path(user_id): Path<Uuid>,
    Json(request): Json<UpdateAccountRequest>,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }

    match auth_service.update_account(user_id, request, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_activity_logs(
    State(auth_service): State<Arc<AuthService>>,
    auth_user: AuthUser,
    Path(user_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }

    match auth_service.get_activity_logs(user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_account(
    State(auth_service): State<Arc<AuthService>>,
    auth_user: AuthUser,
    Path(user_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }

    match auth_service.get_account(user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn delete_account(
    State(auth_service): State<Arc<AuthService>>,
    auth_user: AuthUser,
    Path(user_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }

    match auth_service.delete_account(user_id, auth_user.user_id).await {
        Ok(_) => success_response(
            MessageResponse { message: "Account deleted successfully".to_string() },
            StatusCode::OK,
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn search_students(
    State(auth_service): State<Arc<AuthService>>,
    _auth_user: AuthUser,
    Query(query): Query<SearchStudentsQuery>,
) -> impl IntoResponse {
    let search_query = query.q.unwrap_or_default();
    match auth_service.search_students(&search_query).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}
