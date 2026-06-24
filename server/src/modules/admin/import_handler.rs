use axum::{
    extract::{Multipart, State},
    http::{header, StatusCode},
    response::IntoResponse,
    Json,
};
use std::sync::Arc;

use crate::middleware::auth_middleware::AuthUser;
use crate::modules::admin::csv_handler;
use crate::modules::admin::import_schema::ImportRequest;
use crate::modules::admin::service::AdminService;
use crate::utils::auth_guards::require_admin;
use crate::utils::response::success_response;

const STUDENT_TEMPLATE_HEADERS: &[&str] = &[
    "username",
    "first_name",
    "last_name",
    "lrn",
    "age",
    "sex",
    "track_strand",
    "curriculum",
    "birthdate",
    "birthplace",
    "home_address",
    "father_name",
    "father_contact",
    "mother_name",
    "mother_contact",
    "guardian_name",
    "guardian_contact",
    "date_admitted",
];

pub async fn get_import_template() -> impl IntoResponse {
    let bytes = csv_handler::generate_template(STUDENT_TEMPLATE_HEADERS);
    (
        StatusCode::OK,
        [
            (header::CONTENT_TYPE, "text/csv"),
            (
                header::CONTENT_DISPOSITION,
                "attachment; filename=\"student_import_template.csv\"",
            ),
        ],
        bytes,
    )
}

pub async fn preview_student_import(
    State(admin_service): State<Arc<AdminService>>,
    auth_user: AuthUser,
    mut multipart: Multipart,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }

    let csv_bytes = match csv_handler::extract_csv_bytes(&mut multipart).await {
        Ok(bytes) => bytes,
        Err(e) => {
            return (
                StatusCode::BAD_REQUEST,
                Json(serde_json::json!({ "error": "Bad Request", "message": e })),
            )
                .into_response();
        }
    };

    match admin_service.preview_student_import(&csv_bytes).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn import_students(
    State(admin_service): State<Arc<AdminService>>,
    auth_user: AuthUser,
    Json(request): Json<ImportRequest>,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }

    match admin_service.import_students(request.rows).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}
