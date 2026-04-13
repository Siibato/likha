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
use crate::schema::common::success_response;
use crate::services::assessment::AssessmentService;
use crate::utils::auth_guards::{require_teacher, require_student};

// ===== TEACHER: ASSESSMENT CRUD =====

pub async fn create_assessment(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Json(request): Json<CreateAssessmentRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }

    tracing::info!(
        "Creating assessment - class_id: {}, teacher_id: {}, title: {}",
        class_id,
        auth_user.user_id,
        request.title
    );

    match service.create_assessment(class_id, request, auth_user.user_id, None).await {
        Ok(response) => {
            tracing::info!(
                "Assessment created successfully - assessment_id: {}, class_id: {}, teacher_id: {}",
                response.id,
                class_id,
                auth_user.user_id
            );
            success_response(response, StatusCode::CREATED).into_response()
        },
        Err(e) => {
            tracing::error!(
                "Assessment creation failed - class_id: {}, teacher_id: {}, error: {:?}",
                class_id,
                auth_user.user_id,
                e
            );
            e.into_response()
        },
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
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
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
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn update_assessment(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
    Json(request): Json<UpdateAssessmentRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }

    match service.update_assessment(assessment_id, request, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn delete_assessment(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }

    match service.delete_assessment(assessment_id, auth_user.user_id).await {
        Ok(_) => success_response(MessageResponse {
            message: "Assessment deleted".to_string(),
        }, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn publish_assessment(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }

    match service.publish_assessment(assessment_id, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn unpublish_assessment(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }

    match service.unpublish_assessment(assessment_id, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn release_results(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }

    match service.release_results(assessment_id, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
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
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }

    match service.add_questions(assessment_id, request, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::CREATED).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn update_question(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(question_id): Path<Uuid>,
    Json(request): Json<UpdateQuestionRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }

    match service.update_question(question_id, request, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn delete_question(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(question_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }

    match service.delete_question(question_id, auth_user.user_id).await {
        Ok(_) => success_response(MessageResponse {
            message: "Question deleted".to_string(),
        }, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn reorder_questions(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
    Json(request): Json<ReorderQuestionsRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.reorder_questions(assessment_id, request, auth_user.user_id).await {
        Ok(()) => success_response(
            MessageResponse { message: "Questions reordered".to_string() },
            StatusCode::OK,
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
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }

    match service.get_submissions(assessment_id, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_submission_detail(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(submission_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }

    match service.get_submission_detail(submission_id, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn override_answer(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(answer_id): Path<Uuid>,
    Json(request): Json<OverrideAnswerRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }

    match service.override_answer(answer_id, request, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn grade_essay_answer(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(answer_id): Path<Uuid>,
    Json(request): Json<GradeEssayRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }

    match service.grade_essay_answer(answer_id, request, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_statistics(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }

    match service.get_statistics(assessment_id, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

// ===== STUDENT: TAKING ASSESSMENTS =====

pub async fn start_assessment(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(assessment_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_student(&auth_user) {
        return r;
    }

    match service.start_assessment(assessment_id, auth_user.user_id, None).await {
        Ok(response) => success_response(response, StatusCode::CREATED).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn save_answers(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(submission_id): Path<Uuid>,
    Json(request): Json<SaveAnswersRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_student(&auth_user) {
        return r;
    }

    match service.save_answers(submission_id, request, auth_user.user_id).await {
        Ok(_) => success_response(MessageResponse {
            message: "Answers saved".to_string(),
        }, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn submit_assessment(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(submission_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_student(&auth_user) {
        return r;
    }

    tracing::info!(
        "Assessment submission started - submission_id: {}, student_id: {}",
        submission_id,
        auth_user.user_id
    );

    match service.submit_assessment(submission_id, auth_user.user_id).await {
        Ok(response) => {
            tracing::info!(
                "Assessment submitted successfully - submission_id: {}, student_id: {}, total_points: {}",
                submission_id,
                auth_user.user_id,
                response.total_points
            );
            success_response(response, StatusCode::OK).into_response()
        },
        Err(e) => {
            tracing::error!(
                "Assessment submission failed - submission_id: {}, student_id: {}, error: {:?}",
                submission_id,
                auth_user.user_id,
                e
            );
            e.into_response()
        },
    }
}

pub async fn get_student_results(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(submission_id): Path<Uuid>,
) -> impl IntoResponse {
    if let Err(r) = require_student(&auth_user) {
        return r;
    }

    match service.get_student_results(submission_id, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_assessments_metadata(
    State(service): State<Arc<AssessmentService>>,
    _auth_user: AuthUser,
) -> impl IntoResponse {
    match service.get_assessments_metadata().await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn reorder_assessments(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
    Json(request): Json<ReorderAssessmentsRequest>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.reorder_assessments(class_id, request, auth_user.user_id).await {
        Ok(()) => success_response(
            MessageResponse { message: "Assessments reordered".to_string() },
            StatusCode::OK,
        ).into_response(),
        Err(e) => e.into_response(),
    }
}

pub async fn get_student_assessment_submissions(
    State(service): State<Arc<AssessmentService>>,
    auth_user: AuthUser,
    Path((class_id, student_id)): Path<(Uuid, Uuid)>,
) -> impl IntoResponse {
    if let Err(r) = require_teacher(&auth_user) {
        return r;
    }
    match service.get_student_assessment_submissions(class_id, student_id, auth_user.user_id).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}
