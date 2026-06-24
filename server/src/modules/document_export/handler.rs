use axum::body::Body;
use axum::extract::{Path, Query, State};
use axum::http::{header, StatusCode};
use axum::response::{IntoResponse, Response};
use uuid::Uuid;

use crate::middleware::auth_middleware::AuthUser;
use crate::modules::document_export::schema::ExportGradeQuery;
use crate::modules::document_export::service::DocumentExportService;
use crate::utils::auth_guards::require_teacher;

pub async fn export_class_grades_pdf(
    State(service): State<std::sync::Arc<DocumentExportService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Query(query): Query<ExportGradeQuery>,
) -> Response {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    let term_number = query.term_number.unwrap_or(1);
    match service
        .export_class_grades_pdf(class_id, term_number, auth_user.user_id)
        .await
    {
        Ok(bytes) => pdf_response(bytes),
        Err(e) => e.into_response(),
    }
}

pub async fn export_tos_excel(
    State(service): State<std::sync::Arc<DocumentExportService>>,
    auth_user: AuthUser,
    Path(tos_id): Path<Uuid>,
) -> Response {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service
        .export_tos_excel(tos_id, auth_user.user_id)
        .await
    {
        Ok(bytes) => excel_response_with_name(bytes, "tos.xlsx"),
        Err(e) => e.into_response(),
    }
}

pub async fn export_class_grades_excel(
    State(service): State<std::sync::Arc<DocumentExportService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Query(query): Query<ExportGradeQuery>,
) -> Response {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    let term_number = query.term_number.unwrap_or(1);
    match service
        .export_class_grades_excel(class_id, term_number, auth_user.user_id)
        .await
    {
        Ok(bytes) => excel_response(bytes),
        Err(e) => e.into_response(),
    }
}

pub async fn export_sf9_pdf(
    State(service): State<std::sync::Arc<DocumentExportService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
) -> Response {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service
        .export_sf9_pdf(class_id, student_id, auth_user.user_id)
        .await
    {
        Ok(bytes) => pdf_response(bytes),
        Err(e) => e.into_response(),
    }
}

pub async fn export_sf10_pdf(
    State(service): State<std::sync::Arc<DocumentExportService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
) -> Response {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service
        .export_sf10_pdf(class_id, student_id, auth_user.user_id)
        .await
    {
        Ok(bytes) => pdf_response(bytes),
        Err(e) => e.into_response(),
    }
}

pub async fn export_sf10_excel(
    State(service): State<std::sync::Arc<DocumentExportService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
) -> Response {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service
        .export_sf10_excel(class_id, student_id, auth_user.user_id)
        .await
    {
        Ok(bytes) => excel_response(bytes),
        Err(e) => e.into_response(),
    }
}

fn pdf_response(bytes: Vec<u8>) -> Response {
    (
        StatusCode::OK,
        [
            (header::CONTENT_TYPE, "application/pdf"),
            (
                header::CONTENT_DISPOSITION,
                "attachment; filename=\"grades.pdf\"",
            ),
        ],
        bytes,
    )
        .into_response()
}

fn excel_response(bytes: Vec<u8>) -> Response {
    excel_response_with_name(bytes, "grades.xlsx")
}

fn excel_response_with_name(bytes: Vec<u8>, filename: &str) -> Response {
    Response::builder()
        .status(StatusCode::OK)
        .header(
            header::CONTENT_TYPE,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        )
        .header(
            header::CONTENT_DISPOSITION,
            format!("attachment; filename=\"{}\"", filename),
        )
        .body(Body::from(bytes))
        .expect("failed to build excel response")
}
