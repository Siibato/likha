use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use chrono::NaiveDate;
use std::sync::Arc;
use uuid::Uuid;

use crate::middleware::auth_middleware::AuthUser;
use crate::modules::auth::schema::MessageResponse;
use crate::modules::student_records::schema::*;
use crate::modules::student_records::service::StudentRecordsService;
use crate::utils::auth_guards::require_teacher;
use crate::utils::response::success_response;
use crate::utils::validators::Validator;

fn parse_date(s: &Option<String>) -> Option<NaiveDate> {
    s.as_ref()
        .and_then(|d| NaiveDate::parse_from_str(d, "%Y-%m-%d").ok())
}

// ── Learner Details ──

pub async fn get_learner_details(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    if !service
        .class_repo
        .is_teacher_of_class(auth_user.user_id, class_id)
        .await
        .unwrap_or(false)
    {
        return (
            StatusCode::FORBIDDEN,
            Json(MessageResponse {
                message: "Access denied".to_string(),
            }),
        )
            .into_response();
    }
    match service.repo.get_learner_details(student_id).await {
        Ok(Some(model)) => {
            success_response(LearnerDetailsResponse::from(model), StatusCode::OK).into_response()
        }
        Ok(None) => (
            StatusCode::NOT_FOUND,
            Json(MessageResponse {
                message: "Learner details not found".to_string(),
            }),
        )
            .into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn upsert_learner_details(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
    Json(req): Json<UpsertLearnerDetailsRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    if !service
        .class_repo
        .is_teacher_of_class(auth_user.user_id, class_id)
        .await
        .unwrap_or(false)
    {
        return (
            StatusCode::FORBIDDEN,
            Json(MessageResponse {
                message: "Access denied".to_string(),
            }),
        )
            .into_response();
    }
    let UpsertLearnerDetailsRequest {
        lrn,
        sex,
        track_strand,
        curriculum,
        birthdate,
        birthplace,
        home_address,
        father_name,
        father_contact,
        mother_name,
        mother_contact,
        guardian_name,
        guardian_contact,
        date_admitted,
    } = req;

    let normalized_sex = match Validator::normalize_optional_sex(sex) {
        Ok(value) => value,
        Err(e) => return e.into_response(),
    };

    match service
        .repo
        .upsert_learner_details(
            student_id,
            lrn,
            normalized_sex,
            track_strand,
            curriculum,
            parse_date(&birthdate),
            birthplace,
            home_address,
            father_name,
            father_contact,
            mother_name,
            mother_contact,
            guardian_name,
            guardian_contact,
            parse_date(&date_admitted),
        )
        .await
    {
        Ok(model) => {
            success_response(LearnerDetailsResponse::from(model), StatusCode::OK).into_response()
        }
        Err(e) => e.into_response(),
    }
}

// ── Attendance ──

pub async fn get_attendance(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
    Query(query): Query<AttendanceQuery>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    if !service
        .class_repo
        .is_teacher_of_class(auth_user.user_id, class_id)
        .await
        .unwrap_or(false)
    {
        return (
            StatusCode::FORBIDDEN,
            Json(MessageResponse {
                message: "Access denied".to_string(),
            }),
        )
            .into_response();
    }
    let q_class_id = query.class_id.and_then(|s| Uuid::parse_str(&s).ok());
    match service
        .repo
        .get_attendance(student_id, q_class_id, query.school_year.as_deref())
        .await
    {
        Ok(records) => success_response(
            records
                .into_iter()
                .map(AttendanceResponse::from)
                .collect::<Vec<_>>(),
            StatusCode::OK,
        )
        .into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn upsert_attendance(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
    Json(req): Json<UpsertAttendanceRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    if !service
        .class_repo
        .is_teacher_of_class(auth_user.user_id, class_id)
        .await
        .unwrap_or(false)
    {
        return (
            StatusCode::FORBIDDEN,
            Json(MessageResponse {
                message: "Access denied".to_string(),
            }),
        )
            .into_response();
    }
    let req_class_id = match Uuid::parse_str(&req.class_id) {
        Ok(id) => id,
        Err(_) => {
            return (
                StatusCode::BAD_REQUEST,
                Json(MessageResponse {
                    message: "Invalid class_id".to_string(),
                }),
            )
                .into_response()
        }
    };
    match service
        .repo
        .upsert_attendance(
            student_id,
            req_class_id,
            req.school_year,
            req.month,
            req.school_days,
            req.days_present,
        )
        .await
    {
        Ok(model) => {
            success_response(AttendanceResponse::from(model), StatusCode::OK).into_response()
        }
        Err(e) => e.into_response(),
    }
}

// ── Core Values ──

pub async fn get_core_values(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
    Query(query): Query<CoreValuesQuery>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    if !service
        .class_repo
        .is_teacher_of_class(auth_user.user_id, class_id)
        .await
        .unwrap_or(false)
    {
        return (
            StatusCode::FORBIDDEN,
            Json(MessageResponse {
                message: "Access denied".to_string(),
            }),
        )
            .into_response();
    }
    let q_class_id = query.class_id.and_then(|s| Uuid::parse_str(&s).ok());
    match service
        .repo
        .get_core_values(student_id, q_class_id, query.school_year.as_deref())
        .await
    {
        Ok(records) => success_response(
            records
                .into_iter()
                .map(CoreValuesResponse::from)
                .collect::<Vec<_>>(),
            StatusCode::OK,
        )
        .into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn upsert_core_values(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
    Json(req): Json<UpsertCoreValuesRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    if !service
        .class_repo
        .is_teacher_of_class(auth_user.user_id, class_id)
        .await
        .unwrap_or(false)
    {
        return (
            StatusCode::FORBIDDEN,
            Json(MessageResponse {
                message: "Access denied".to_string(),
            }),
        )
            .into_response();
    }
    let req_class_id = match Uuid::parse_str(&req.class_id) {
        Ok(id) => id,
        Err(_) => {
            return (
                StatusCode::BAD_REQUEST,
                Json(MessageResponse {
                    message: "Invalid class_id".to_string(),
                }),
            )
                .into_response()
        }
    };
    match service
        .repo
        .upsert_core_values(
            student_id,
            req_class_id,
            req.school_year,
            req.term_number,
            req.core_value_id,
            req.marking,
        )
        .await
    {
        Ok(model) => {
            success_response(CoreValuesResponse::from(model), StatusCode::OK).into_response()
        }
        Err(e) => e.into_response(),
    }
}

// ── School History ──

pub async fn get_school_history(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    if !service
        .class_repo
        .is_teacher_of_class(auth_user.user_id, class_id)
        .await
        .unwrap_or(false)
    {
        return (
            StatusCode::FORBIDDEN,
            Json(MessageResponse {
                message: "Access denied".to_string(),
            }),
        )
            .into_response();
    }
    match service.repo.get_school_history(student_id).await {
        Ok(records) => success_response(
            records
                .into_iter()
                .map(SchoolHistoryResponse::from)
                .collect::<Vec<_>>(),
            StatusCode::OK,
        )
        .into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn create_school_history(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
    Json(req): Json<CreateSchoolHistoryRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    if !service
        .class_repo
        .is_teacher_of_class(auth_user.user_id, class_id)
        .await
        .unwrap_or(false)
    {
        return (
            StatusCode::FORBIDDEN,
            Json(MessageResponse {
                message: "Access denied".to_string(),
            }),
        )
            .into_response();
    }
    match service
        .repo
        .create_school_history(
            student_id,
            req.school_name,
            req.school_id,
            req.grade_level,
            req.school_year,
            req.section,
            parse_date(&req.date_from),
            parse_date(&req.date_to),
            req.record_type,
        )
        .await
    {
        Ok(model) => success_response(SchoolHistoryResponse::from(model), StatusCode::CREATED)
            .into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn update_school_history(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Path((class_id, _student_id, history_id)): Path<(Uuid, Uuid, Uuid)>,
    Json(req): Json<UpdateSchoolHistoryRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    if !service
        .class_repo
        .is_teacher_of_class(auth_user.user_id, class_id)
        .await
        .unwrap_or(false)
    {
        return (
            StatusCode::FORBIDDEN,
            Json(MessageResponse {
                message: "Access denied".to_string(),
            }),
        )
            .into_response();
    }
    match service
        .repo
        .update_school_history(
            history_id,
            req.school_name,
            req.school_id,
            req.grade_level,
            req.school_year,
            req.section,
            req.date_from.map(|d| d.and_then(|s| parse_date(&Some(s)))),
            req.date_to.map(|d| d.and_then(|s| parse_date(&Some(s)))),
            req.record_type,
        )
        .await
    {
        Ok(model) => {
            success_response(SchoolHistoryResponse::from(model), StatusCode::OK).into_response()
        }
        Err(e) => e.into_response(),
    }
}

pub async fn delete_school_history(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Path((class_id, _student_id, history_id)): Path<(Uuid, Uuid, Uuid)>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    if !service
        .class_repo
        .is_teacher_of_class(auth_user.user_id, class_id)
        .await
        .unwrap_or(false)
    {
        return (
            StatusCode::FORBIDDEN,
            Json(MessageResponse {
                message: "Access denied".to_string(),
            }),
        )
            .into_response();
    }
    match service.repo.delete_school_history(history_id).await {
        Ok(()) => success_response(
            MessageResponse {
                message: "Deleted".to_string(),
            },
            StatusCode::OK,
        )
        .into_response(),
        Err(e) => e.into_response(),
    }
}

// ── Previous Subjects ──

pub async fn get_previous_subjects(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
    Query(query): Query<AttendanceQuery>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    if !service
        .class_repo
        .is_teacher_of_class(auth_user.user_id, class_id)
        .await
        .unwrap_or(false)
    {
        return (
            StatusCode::FORBIDDEN,
            Json(MessageResponse {
                message: "Access denied".to_string(),
            }),
        )
            .into_response();
    }
    let q_history_id = query.class_id.and_then(|s| Uuid::parse_str(&s).ok());
    match service
        .repo
        .get_previous_subjects(student_id, q_history_id)
        .await
    {
        Ok(records) => {
            let mut responses: Vec<PreviousSubjectResponse> = Vec::new();
            for s in records {
                let term_grades = service
                    .repo
                    .get_term_grades_for_subject(s.id)
                    .await
                    .unwrap_or_default();
                responses.push(PreviousSubjectResponse::from_with_term_grades(
                    s,
                    term_grades,
                ));
            }
            success_response(responses, StatusCode::OK).into_response()
        }
        Err(e) => e.into_response(),
    }
}

pub async fn upsert_previous_subject(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
    Json(req): Json<UpsertPreviousSubjectRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    if !service
        .class_repo
        .is_teacher_of_class(auth_user.user_id, class_id)
        .await
        .unwrap_or(false)
    {
        return (
            StatusCode::FORBIDDEN,
            Json(MessageResponse {
                message: "Access denied".to_string(),
            }),
        )
            .into_response();
    }
    let req_history_id = match Uuid::parse_str(&req.school_history_id) {
        Ok(id) => id,
        Err(_) => {
            return (
                StatusCode::BAD_REQUEST,
                Json(MessageResponse {
                    message: "Invalid school_history_id".to_string(),
                }),
            )
                .into_response()
        }
    };
    match service
        .repo
        .upsert_previous_subject(
            student_id,
            req_history_id,
            req.subject_name,
            req.subject_group,
            req.term_type,
            req.term_grades,
            req.final_grade,
            req.descriptor,
        )
        .await
    {
        Ok(model) => {
            let term_grades = service
                .repo
                .get_term_grades_for_subject(model.id)
                .await
                .unwrap_or_default();
            success_response(
                PreviousSubjectResponse::from_with_term_grades(model, term_grades),
                StatusCode::OK,
            )
            .into_response()
        }
        Err(e) => e.into_response(),
    }
}

// ── Previous Attendance ──

pub async fn get_previous_attendance(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
    Query(query): Query<AttendanceQuery>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    if !service
        .class_repo
        .is_teacher_of_class(auth_user.user_id, class_id)
        .await
        .unwrap_or(false)
    {
        return (
            StatusCode::FORBIDDEN,
            Json(MessageResponse {
                message: "Access denied".to_string(),
            }),
        )
            .into_response();
    }
    let q_history_id = query.class_id.and_then(|s| Uuid::parse_str(&s).ok());
    match service
        .repo
        .get_previous_attendance(student_id, q_history_id)
        .await
    {
        Ok(records) => success_response(
            records
                .into_iter()
                .map(PreviousAttendanceResponse::from)
                .collect::<Vec<_>>(),
            StatusCode::OK,
        )
        .into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn upsert_previous_attendance(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
    Json(req): Json<UpsertPreviousAttendanceRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    if !service
        .class_repo
        .is_teacher_of_class(auth_user.user_id, class_id)
        .await
        .unwrap_or(false)
    {
        return (
            StatusCode::FORBIDDEN,
            Json(MessageResponse {
                message: "Access denied".to_string(),
            }),
        )
            .into_response();
    }
    let req_history_id = match Uuid::parse_str(&req.school_history_id) {
        Ok(id) => id,
        Err(_) => {
            return (
                StatusCode::BAD_REQUEST,
                Json(MessageResponse {
                    message: "Invalid school_history_id".to_string(),
                }),
            )
                .into_response()
        }
    };
    match service
        .repo
        .upsert_previous_attendance(
            student_id,
            req_history_id,
            req.school_year,
            req.month,
            req.school_days,
            req.days_present,
        )
        .await
    {
        Ok(model) => success_response(PreviousAttendanceResponse::from(model), StatusCode::OK)
            .into_response(),
        Err(e) => e.into_response(),
    }
}

// ── SF10 ──

pub async fn get_sf10(
    State(service): State<Arc<StudentRecordsService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service
        .get_sf10(class_id, student_id, auth_user.user_id)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}
