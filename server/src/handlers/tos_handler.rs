use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use std::sync::Arc;
use uuid::Uuid;

use crate::middleware::auth_middleware::AuthUser;
use crate::schema::auth_schema::MessageResponse;
use crate::schema::common::success_response;
use crate::schema::tos_schema::*;
use crate::services::tos::TosService;
use crate::utils::auth_guards::require_teacher;

// ===== TOS CRUD =====

pub async fn list_tos(
    State(service): State<Arc<TosService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.list_tos_for_class(class_id, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn create_tos(
    State(service): State<Arc<TosService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Json(request): Json<CreateTosRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.create_tos(class_id, auth_user.user_id, request, None).await {
        Ok(response) => success_response(response, StatusCode::CREATED).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_tos(
    State(service): State<Arc<TosService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.get_tos(id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn update_tos(
    State(service): State<Arc<TosService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
    Json(request): Json<UpdateTosRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.update_tos(id, auth_user.user_id, request).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn delete_tos(
    State(service): State<Arc<TosService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.delete_tos(id, auth_user.user_id).await {
        Ok(_) => success_response(MessageResponse {
            message: "Table of Specifications deleted".to_string(),
        }, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

// ===== COMPETENCIES =====

pub async fn add_competency(
    State(service): State<Arc<TosService>>,
    auth_user: AuthUser,
    Path(tos_id): Path<Uuid>,
    Json(request): Json<CreateCompetencyRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.add_competency(tos_id, auth_user.user_id, request).await {
        Ok(response) => success_response(response, StatusCode::CREATED).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn update_competency(
    State(service): State<Arc<TosService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
    Json(request): Json<UpdateCompetencyRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.update_competency(id, auth_user.user_id, request).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn delete_competency(
    State(service): State<Arc<TosService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.delete_competency(id, auth_user.user_id).await {
        Ok(_) => success_response(MessageResponse {
            message: "Competency deleted".to_string(),
        }, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn bulk_add_competencies(
    State(service): State<Arc<TosService>>,
    auth_user: AuthUser,
    Path(tos_id): Path<Uuid>,
    Json(request): Json<BulkAddCompetenciesRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.bulk_add_competencies(tos_id, auth_user.user_id, request).await {
        Ok(response) => success_response(response, StatusCode::CREATED).into_response(),
        Err(e) => e.into_response(),
    }
}

// ===== MELCS SEARCH =====

pub async fn search_melcs(
    State(service): State<Arc<TosService>>,
    auth_user: AuthUser,
    Query(query): Query<MelcsSearchQuery>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    let limit = query.limit.unwrap_or(30).clamp(1, 200);
    let offset = query.offset.unwrap_or(0).max(0);
    match service
        .search_melcs(
            query.subject.as_deref(),
            query.grade_level.as_deref(),
            query.quarter,
            query.q.as_deref(),
            limit,
            offset,
        )
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}
