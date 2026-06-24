use axum::{
    extract::{Multipart, Query, State},
    http::{header, StatusCode},
    response::IntoResponse,
    Json,
};
use std::sync::Arc;

use crate::middleware::auth_middleware::AuthUser;
use crate::modules::admin::csv_handler;
use crate::modules::student_records::import_schema::{HistoryTypeQuery, ImportRequest};
use crate::modules::student_records::service::StudentRecordsService;
use crate::modules::student_records::service_operations as ops;
use crate::utils::auth_guards::require_admin;
use crate::utils::response::success_response;

const SCHOOL_HISTORY_TEMPLATE_HEADERS: &[&str] = &[
    "username",
    "full_name",
    "school_name",
    "school_id",
    "grade_level",
    "school_year",
    "section",
    "date_from",
    "date_to",
    "record_type",
];

const SUBJECTS_TEMPLATE_HEADERS: &[&str] = &[
    "username",
    "full_name",
    "school_name",
    "school_year",
    "subject_name",
    "subject_group",
    "term_type",
    "final_grade",
    "descriptor",
    "term1_grade",
    "term2_grade",
    "term3_grade",
    "term4_grade",
];

const ATTENDANCE_TEMPLATE_HEADERS: &[&str] = &[
    "username",
    "full_name",
    "school_name",
    "school_year",
    "month",
    "school_days",
    "days_present",
];

pub async fn get_history_template(Query(query): Query<HistoryTypeQuery>) -> impl IntoResponse {
    let headers = match query.history_type.as_str() {
        "subjects" => SUBJECTS_TEMPLATE_HEADERS,
        "attendance" => ATTENDANCE_TEMPLATE_HEADERS,
        _ => SCHOOL_HISTORY_TEMPLATE_HEADERS,
    };

    let bytes = csv_handler::generate_template(headers);
    (
        StatusCode::OK,
        [
            (header::CONTENT_TYPE, "text/csv"),
            (
                header::CONTENT_DISPOSITION,
                "attachment; filename=\"history_import_template.csv\"",
            ),
        ],
        bytes,
    )
}

pub async fn preview_history_import(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Query(query): Query<HistoryTypeQuery>,
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

    let result = match query.history_type.as_str() {
        "subjects" => ops::preview_subjects(&service.db, &csv_bytes).await,
        "attendance" => ops::preview_attendance(&service.db, &csv_bytes).await,
        _ => ops::preview_school_history(&service.db, &csv_bytes).await,
    };

    match result {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn import_history(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Query(query): Query<HistoryTypeQuery>,
    Json(request): Json<ImportRequest>,
) -> impl IntoResponse {
    if let Err(e) = require_admin(&auth_user) {
        return e.into_response();
    }

    let result = match query.history_type.as_str() {
        "subjects" => ops::import_subjects(&service.db, &request.rows).await,
        "attendance" => ops::import_attendance(&service.db, &request.rows).await,
        _ => ops::import_school_history(&service.db, &request.rows).await,
    };

    match result {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}
