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
use crate::schema::assignment_schema::*;
use crate::schema::auth_schema::MessageResponse;
use crate::schema::common::success_response;
use crate::services::assignment_service::AssignmentService;
use crate::utils::error::AppError;

// ===== TEACHER: ASSIGNMENT CRUD =====

pub async fn create_assignment(
    State(service): State<Arc<AssignmentService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Json(request): Json<CreateAssignmentRequest>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service
        .create_assignment(class_id, request, auth_user.user_id)
        .await
    {
        Ok(response) => success_response(response, StatusCode::CREATED).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_assignments(
    State(service): State<Arc<AssignmentService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
) -> impl IntoResponse {
    match service
        .get_assignments(class_id, auth_user.user_id, &auth_user.role)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_student_assignments(
    State(service): State<Arc<AssignmentService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "student" {
        return AppError::Forbidden("Student access required".to_string()).into_response();
    }

    match service
        .get_student_assignments(class_id, auth_user.user_id)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_assignment_detail(
    State(service): State<Arc<AssignmentService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    match service
        .get_assignment_detail(id, auth_user.user_id, &auth_user.role)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn update_assignment(
    State(service): State<Arc<AssignmentService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
    Json(request): Json<UpdateAssignmentRequest>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service
        .update_assignment(id, request, auth_user.user_id)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn delete_assignment(
    State(service): State<Arc<AssignmentService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.delete_assignment(id, auth_user.user_id).await {
        Ok(()) => success_response(MessageResponse {
            message: "Assignment deleted".to_string(),
        }, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn publish_assignment(
    State(service): State<Arc<AssignmentService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.publish_assignment(id, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_submissions(
    State(service): State<Arc<AssignmentService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.get_submissions(id, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_submission_detail(
    State(service): State<Arc<AssignmentService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    match service
        .get_submission_detail(id, auth_user.user_id, &auth_user.role)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn grade_submission(
    State(service): State<Arc<AssignmentService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
    Json(request): Json<GradeSubmissionRequest>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service
        .grade_submission(id, request, auth_user.user_id)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn return_submission(
    State(service): State<Arc<AssignmentService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.return_submission(id, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

// ===== STUDENT: SUBMISSION FLOW =====

pub async fn create_submission(
    State(service): State<Arc<AssignmentService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
    Json(request): Json<SubmitTextRequest>,
) -> impl IntoResponse {
    if auth_user.role != "student" {
        return AppError::Forbidden("Student access required".to_string()).into_response();
    }

    match service
        .create_or_get_submission(id, auth_user.user_id, request.text_content)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn upload_file(
    State(service): State<Arc<AssignmentService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
    mut multipart: Multipart,
) -> impl IntoResponse {
    if auth_user.role != "student" {
        return AppError::Forbidden("Student access required".to_string()).into_response();
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
            .upload_file(id, auth_user.user_id, file_name, content_type, data)
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

pub async fn delete_submission_file(
    State(service): State<Arc<AssignmentService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "student" {
        return AppError::Forbidden("Student access required".to_string()).into_response();
    }

    match service.delete_file(id, auth_user.user_id).await {
        Ok(()) => success_response(MessageResponse {
            message: "File deleted".to_string(),
        }, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn submit_assignment(
    State(service): State<Arc<AssignmentService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "student" {
        return AppError::Forbidden("Student access required".to_string()).into_response();
    }

    match service.submit_assignment(id, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn download_file(
    State(service): State<Arc<AssignmentService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
) -> Response {
    match service
        .download_file(id, auth_user.user_id, &auth_user.role)
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
