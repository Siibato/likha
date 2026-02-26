use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use std::sync::Arc;
use uuid::Uuid;

use crate::schema::auth_schema::MessageResponse;
use crate::schema::class_schema::{AddStudentRequest, CreateClassRequest, SearchStudentsQuery, UpdateClassRequest, ClassMetadataResponse};
use crate::schema::common::success_response;
use crate::services::auth_service::AuthService;
use crate::services::class_service::ClassService;
use crate::middleware::auth_middleware::AuthUser;
use crate::utils::error::AppError;

pub async fn create_class(
    State(class_service): State<Arc<ClassService>>,
    auth_user: AuthUser,
    Json(request): Json<CreateClassRequest>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match class_service.create_class(request, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::CREATED).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn update_class(
    State(class_service): State<Arc<ClassService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Json(request): Json<UpdateClassRequest>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match class_service.update_class(class_id, request, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_classes(
    State(class_service): State<Arc<ClassService>>,
    auth_user: AuthUser,
) -> impl IntoResponse {
    let result = match auth_user.role.as_str() {
        "teacher" => class_service.get_teacher_classes(auth_user.user_id).await,
        "student" => class_service.get_student_classes(auth_user.user_id).await,
        _ => return AppError::Forbidden("Access denied".to_string()).into_response(),
    };

    match result {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_class_detail(
    State(class_service): State<Arc<ClassService>>,
    _auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
) -> impl IntoResponse {
    match class_service.get_class_detail(class_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn add_student(
    State(class_service): State<Arc<ClassService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Json(request): Json<AddStudentRequest>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match class_service
        .add_student(class_id, request.student_id, auth_user.user_id)
        .await
    {
        Ok(response) => success_response(response, StatusCode::CREATED).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn remove_student(
    State(class_service): State<Arc<ClassService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match class_service
        .remove_student(class_id, student_id, auth_user.user_id)
        .await
    {
        Ok(_) => success_response(MessageResponse {
            message: "Student removed from class".to_string(),
        }, StatusCode::OK).into_response(),
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

pub async fn get_classes_metadata(
    State(class_service): State<Arc<ClassService>>,
    auth_user: AuthUser,
) -> impl IntoResponse {
    match class_service.get_classes_metadata(auth_user.user_id, &auth_user.role).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}
