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
    let period = query.period.unwrap_or(1);
    match service.export_class_grades_pdf(class_id, period, auth_user.user_id).await {
        Ok(bytes) => pdf_response(bytes),
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
    let period = query.period.unwrap_or(1);
    match service.export_class_grades_excel(class_id, period, auth_user.user_id).await {
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
    match service.export_sf9_pdf(class_id, student_id, auth_user.user_id).await {
        Ok(bytes) => pdf_response(bytes),
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
    (
        StatusCode::OK,
        [
            (
                header::CONTENT_TYPE,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            ),
            (
                header::CONTENT_DISPOSITION,
                "attachment; filename=\"grades.xlsx\"",
            ),
        ],
        bytes,
    )
        .into_response()
}
