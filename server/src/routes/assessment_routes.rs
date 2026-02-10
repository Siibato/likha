use axum::{
    routing::{delete, get, post, put},
    Router,
};
use std::sync::Arc;

use crate::handlers::assessment_handler;
use crate::services::assessment_service::AssessmentService;

pub fn routes(assessment_service: Arc<AssessmentService>) -> Router {
    Router::new()
        // Assessment CRUD
        .route(
            "/classes/{class_id}/assessments",
            post(assessment_handler::create_assessment),
        )
        .route(
            "/classes/{class_id}/assessments",
            get(assessment_handler::get_assessments),
        )
        .route(
            "/assessments/{id}",
            get(assessment_handler::get_assessment_detail),
        )
        .route(
            "/assessments/{id}",
            put(assessment_handler::update_assessment),
        )
        .route(
            "/assessments/{id}",
            delete(assessment_handler::delete_assessment),
        )
        .route(
            "/assessments/{id}/publish",
            post(assessment_handler::publish_assessment),
        )
        .route(
            "/assessments/{id}/release-results",
            post(assessment_handler::release_results),
        )
        // Questions
        .route(
            "/assessments/{id}/questions",
            post(assessment_handler::add_questions),
        )
        .route(
            "/questions/{id}",
            put(assessment_handler::update_question),
        )
        .route(
            "/questions/{id}",
            delete(assessment_handler::delete_question),
        )
        // Submissions & grading
        .route(
            "/assessments/{id}/submissions",
            get(assessment_handler::get_submissions),
        )
        .route(
            "/submissions/{id}",
            get(assessment_handler::get_submission_detail),
        )
        .route(
            "/submission-answers/{id}/override",
            put(assessment_handler::override_answer),
        )
        .route(
            "/assessments/{id}/statistics",
            get(assessment_handler::get_statistics),
        )
        // Student endpoints
        .route(
            "/assessments/{id}/start",
            post(assessment_handler::start_assessment),
        )
        .route(
            "/submissions/{id}/answers",
            put(assessment_handler::save_answers),
        )
        .route(
            "/submissions/{id}/submit",
            post(assessment_handler::submit_assessment),
        )
        .route(
            "/submissions/{id}/results",
            get(assessment_handler::get_student_results),
        )
        .with_state(assessment_service)
}
