use axum::{
    body::Body,
    extract::{Multipart, Path, State},
    http::{header, StatusCode},
    response::{IntoResponse, Response},
    Json,
};
use std::sync::Arc;
use uuid::Uuid;

use crate::middleware::auth_middleware::AuthUser;
use crate::schema::auth_schema::MessageResponse;
use crate::schema::common::success_response;
use crate::schema::learning_material_schema::*;
use crate::services::learning_material::LearningMaterialService;
use crate::utils::error::AppError;

// ===== MATERIAL CRUD =====

pub async fn create_material(
    State(service): State<Arc<LearningMaterialService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Json(request): Json<CreateMaterialRequest>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service
        .create_material(class_id, request, auth_user.user_id, None)
        .await
    {
        Ok(response) => success_response(response, StatusCode::CREATED).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_materials(
    State(service): State<Arc<LearningMaterialService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
) -> impl IntoResponse {
    match service
        .get_materials(class_id, auth_user.user_id, &auth_user.role)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_material_detail(
    State(service): State<Arc<LearningMaterialService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    match service
        .get_material_detail(id, auth_user.user_id, &auth_user.role)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn update_material(
    State(service): State<Arc<LearningMaterialService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
    Json(request): Json<UpdateMaterialRequest>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service
        .update_material(id, request, auth_user.user_id)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn delete_material(
    State(service): State<Arc<LearningMaterialService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.delete_material(id, auth_user.user_id).await {
        Ok(()) => success_response(MessageResponse {
            message: "Material deleted".to_string(),
        }, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn reorder_material(
    State(service): State<Arc<LearningMaterialService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
    Json(request): Json<ReorderMaterialRequest>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service
        .reorder_material(id, request, auth_user.user_id)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn reorder_materials(
    State(service): State<Arc<LearningMaterialService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Json(request): Json<ReorderMaterialsRequest>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.reorder_materials(class_id, request, auth_user.user_id).await {
        Ok(()) => success_response(MessageResponse {
            message: "Materials reordered".to_string(),
        }, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

// ===== FILE MANAGEMENT =====

pub async fn upload_file(
    State(service): State<Arc<LearningMaterialService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
    mut multipart: Multipart,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    while let Ok(Some(field)) = multipart.next_field().await {
        let file_name = match field.file_name() {
            Some(name) => name.to_string(),
            None => continue,
        };

        let content_type = field
            .content_type()
            .unwrap_or("application/octet-stream")
            .to_string();

        let data = match field.bytes().await {
            Ok(bytes) => bytes.to_vec(),
            Err(e) => {
                return AppError::BadRequest(format!("Failed to read file: {}", e))
                    .into_response();
            }
        };

        match service
            .upload_file(id, file_name, content_type, data, auth_user.user_id)
            .await
        {
            Ok(response) => {
                return success_response(response, StatusCode::CREATED).into_response();
            }
            Err(e) => return e.into_response(),
        }
    }

    AppError::BadRequest("No file provided".to_string()).into_response()
}

pub async fn delete_file(
    State(service): State<Arc<LearningMaterialService>>,
    auth_user: AuthUser,
    Path(file_id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.delete_file(file_id, auth_user.user_id).await {
        Ok(()) => success_response(MessageResponse {
            message: "File deleted".to_string(),
        }, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn download_file(
    State(service): State<Arc<LearningMaterialService>>,
    auth_user: AuthUser,
    Path(file_id): Path<Uuid>,
) -> Response {
    match service
        .download_file(file_id, auth_user.user_id, &auth_user.role)
        .await
    {
        Ok((file_name, content_type, data)) => Response::builder()
            .status(StatusCode::OK)
            .header(header::CONTENT_TYPE, content_type)
            .header(
                header::CONTENT_DISPOSITION,
                format!("attachment; filename=\"{}\"", file_name),
            )
            .body(Body::from(data))
            .unwrap_or_else(|_| {
                AppError::InternalServerError("Failed to build response".to_string())
                    .into_response()
            }),
        Err(e) => e.into_response(),
    }
}

pub async fn get_materials_metadata(
    State(service): State<Arc<LearningMaterialService>>,
    _auth_user: AuthUser,
) -> impl IntoResponse {
    match service.get_materials_metadata().await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}
