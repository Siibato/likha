use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use std::sync::Arc;
use uuid::Uuid;

use crate::middleware::auth_middleware::AuthUser;
use crate::schema::common::success_response;
use crate::schema::grading_schema::*;
use crate::services::grade_computation::GradeComputationService;
use crate::utils::auth_guards::require_teacher;

// ===== GRADING CONFIG =====

pub async fn get_grading_config(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.get_grading_config(class_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn setup_grading_config(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Json(request): Json<SetupGradingConfigRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service
        .setup_grading(
            class_id,
            request.grade_level,
            request.subject_group,
            request.school_year,
            request.semester,
        )
        .await
    {
        Ok(response) => success_response(response, StatusCode::CREATED).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn update_grading_config(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Json(request): Json<UpdateGradingConfigRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service
        .update_grading_config(class_id, request.grading_period_number, request.ww_weight, request.pt_weight, request.qa_weight)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

// ===== GRADE ITEMS =====

pub async fn get_grade_items(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Query(query): Query<QuarterQuery>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    let quarter = query.grading_period_number.unwrap_or(1);
    match service.get_grade_items(class_id, quarter).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn create_grade_item(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Json(request): Json<CreateGradeItemRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.create_grade_item(class_id, request).await {
        Ok(response) => success_response(response, StatusCode::CREATED).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn update_grade_item(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
    Json(request): Json<UpdateGradeItemRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.update_grade_item(id, request).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn delete_grade_item(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.delete_grade_item(id).await {
        Ok(()) => StatusCode::NO_CONTENT.into_response(),
        Err(e) => e.into_response(),
    }
}

// ===== GRADE SCORES =====

pub async fn get_item_scores(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(item_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.get_item_scores(item_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn update_item_scores(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(item_id): Path<Uuid>,
    Json(request): Json<BulkUpdateScoresRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    let scores: Vec<(Uuid, f64)> = request
        .scores
        .into_iter()
        .map(|s| (s.student_id, s.score))
        .collect();
    match service.save_scores(item_id, scores).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn override_score(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(score_id): Path<Uuid>,
    Json(request): Json<OverrideScoreRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.set_override(score_id, request.override_score).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn delete_score_override(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(score_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.clear_override(score_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

// ===== COMPUTED GRADES =====

pub async fn get_grades(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Query(query): Query<QuarterQuery>,
) -> impl IntoResponse {
    let quarter = query.grading_period_number.unwrap_or(1);
    if auth_user.role == "student" {
        // Student can only see their own grades
        match service
            .get_student_quarterly_grade(class_id, auth_user.user_id, quarter)
            .await
        {
            Ok(response) => success_response(response, StatusCode::OK).into_response(),
            Err(e) => e.into_response(),
        }
    } else if auth_user.role == "teacher" {
        match service.get_quarterly_grades(class_id, quarter).await {
            Ok(response) => success_response(response, StatusCode::OK).into_response(),
            Err(e) => e.into_response(),
        }
    } else {
        StatusCode::FORBIDDEN.into_response()
    }
}

pub async fn compute_grades(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Query(query): Query<QuarterQuery>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    let quarter = query.grading_period_number.unwrap_or(1);
    match service.compute_class_quarterly(class_id, quarter).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_final_grades(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role == "student" {
        match service
            .compute_final_grade(class_id, auth_user.user_id)
            .await
        {
            Ok(response) => success_response(response, StatusCode::OK).into_response(),
            Err(e) => e.into_response(),
        }
    } else if auth_user.role == "teacher" {
        // Get final grades for all students
        match service.repo.get_enrolled_student_ids(class_id).await {
            Ok(student_ids) => {
                let mut results = Vec::new();
                for sid in student_ids {
                    match service.compute_final_grade(class_id, sid).await {
                        Ok(fg) => results.push(fg),
                        Err(e) => return e.into_response(),
                    }
                }
                success_response(results, StatusCode::OK).into_response()
            }
            Err(e) => e.into_response(),
        }
    } else {
        StatusCode::FORBIDDEN.into_response()
    }
}

pub async fn get_grade_summary(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Query(query): Query<QuarterQuery>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    let quarter = query.grading_period_number.unwrap_or(1);
    match service.get_grade_summary(class_id, quarter).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

// ===== STUDENT ENDPOINTS =====

pub async fn get_my_grades(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
) -> impl IntoResponse {
    match service
        .get_student_all_quarters(class_id, auth_user.user_id)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_my_quarter_grades(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path((class_id, quarter)): Path<(Uuid, i32)>,
) -> impl IntoResponse {
    match service
        .get_student_quarterly_grade(class_id, auth_user.user_id, quarter)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

// ===== UTILITY =====

pub async fn get_deped_presets(
    _auth_user: AuthUser,
) -> impl IntoResponse {
    let presets: Vec<PresetInfo> = crate::services::grade_computation::deped_weights::get_all_presets()
        .into_iter()
        .map(|(key, label, preset)| PresetInfo {
            key: key.to_string(),
            label: label.to_string(),
            ww: preset.ww,
            pt: preset.pt,
            qa: preset.qa,
        })
        .collect();
    success_response(
        DepEdPresetsResponse { presets },
        StatusCode::OK,
    )
    .into_response()
}

// ===== GENERAL AVERAGE =====

pub async fn get_general_averages(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.compute_general_averages(class_id, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

// ===== SF9/SF10 =====

pub async fn get_sf9(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.compute_sf9(class_id, student_id, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_sf10(
    State(service): State<Arc<GradeComputationService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    // SF10 initially returns the same data as SF9 (current school year only)
    match service.compute_sf9(class_id, student_id, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}
