use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use std::sync::Arc;
use uuid::Uuid;

use crate::middleware::auth_middleware::AuthUser;
use crate::schema::assessment_schema::*;
use crate::schema::auth_schema::MessageResponse;
use crate::schema::common::ApiResponse;
use crate::services::assessment_service::AssessmentService;
use crate::utils::error::AppError;

// ===== TEACHER: ASSESSMENT CRUD =====

pub async fn create_assessment(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Json(request): Json<CreateAssessmentRequest>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.create_assessment(class_id, request, auth_user.user_id).await {
        Ok(response) => (
            StatusCode::CREATED,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_assessments(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
) -> impl IntoResponse {
    match service
        .get_assessments(class_id, auth_user.user_id, &auth_user.role)
        .await
    {
        Ok(response) => (
            StatusCode::OK,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_assessment_detail(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
) -> impl IntoResponse {
    match service
        .get_assessment_detail(assessment_id, auth_user.user_id, &auth_user.role)
        .await
    {
        Ok(response) => (
            StatusCode::OK,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn update_assessment(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
    Json(request): Json<UpdateAssessmentRequest>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.update_assessment(assessment_id, request, auth_user.user_id).await {
        Ok(response) => (
            StatusCode::OK,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn delete_assessment(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.delete_assessment(assessment_id, auth_user.user_id).await {
        Ok(_) => (
            StatusCode::OK,
            Json(ApiResponse::success(MessageResponse {
                message: "Assessment deleted".to_string(),
            })),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn publish_assessment(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.publish_assessment(assessment_id, auth_user.user_id).await {
        Ok(response) => (
            StatusCode::OK,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn release_results(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.release_results(assessment_id, auth_user.user_id).await {
        Ok(response) => (
            StatusCode::OK,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

// ===== TEACHER: QUESTIONS =====

pub async fn add_questions(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
    Json(request): Json<AddQuestionsRequest>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.add_questions(assessment_id, request, auth_user.user_id).await {
        Ok(response) => (
            StatusCode::CREATED,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn update_question(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(question_id): Path<Uuid>,
    Json(request): Json<UpdateQuestionRequest>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.update_question(question_id, request, auth_user.user_id).await {
        Ok(response) => (
            StatusCode::OK,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn delete_question(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(question_id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.delete_question(question_id, auth_user.user_id).await {
        Ok(_) => (
            StatusCode::OK,
            Json(ApiResponse::success(MessageResponse {
                message: "Question deleted".to_string(),
            })),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

// ===== TEACHER: SUBMISSIONS & GRADING =====

pub async fn get_submissions(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.get_submissions(assessment_id, auth_user.user_id).await {
        Ok(response) => (
            StatusCode::OK,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_submission_detail(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(submission_id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.get_submission_detail(submission_id, auth_user.user_id).await {
        Ok(response) => (
            StatusCode::OK,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn override_answer(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(answer_id): Path<Uuid>,
    Json(request): Json<OverrideAnswerRequest>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.override_answer(answer_id, request, auth_user.user_id).await {
        Ok(response) => (
            StatusCode::OK,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_statistics(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "teacher" {
        return AppError::Forbidden("Teacher access required".to_string()).into_response();
    }

    match service.get_statistics(assessment_id, auth_user.user_id).await {
        Ok(response) => (
            StatusCode::OK,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

// ===== STUDENT: TAKING ASSESSMENTS =====

pub async fn start_assessment(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "student" {
        return AppError::Forbidden("Student access required".to_string()).into_response();
    }

    match service.start_assessment(assessment_id, auth_user.user_id).await {
        Ok(response) => (
            StatusCode::CREATED,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn save_answers(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(submission_id): Path<Uuid>,
    Json(request): Json<SaveAnswersRequest>,
) -> impl IntoResponse {
    if auth_user.role != "student" {
        return AppError::Forbidden("Student access required".to_string()).into_response();
    }

    match service.save_answers(submission_id, request, auth_user.user_id).await {
        Ok(_) => (
            StatusCode::OK,
            Json(ApiResponse::success(MessageResponse {
                message: "Answers saved".to_string(),
            })),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn submit_assessment(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(submission_id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "student" {
        return AppError::Forbidden("Student access required".to_string()).into_response();
    }

    match service.submit_assessment(submission_id, auth_user.user_id).await {
        Ok(response) => (
            StatusCode::OK,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_student_results(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(submission_id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "student" {
        return AppError::Forbidden("Student access required".to_string()).into_response();
    }

    match service.get_student_results(submission_id, auth_user.user_id).await {
        Ok(response) => (
            StatusCode::OK,
            Json(ApiResponse::success(response)),
        ).into_response(),
        Err(e) => e.into_response(),
    }
}
