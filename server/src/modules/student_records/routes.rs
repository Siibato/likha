use axum::{
    routing::{delete, get, post, put},
    Router,
};
use std::sync::Arc;

use crate::modules::student_records::handler;
use crate::modules::student_records::service::StudentRecordsService;

pub fn routes(service: Arc<StudentRecordsService>) -> Router {
    Router::new()
        // Learner Details
        .route(
            "/classes/{class_id}/students/{student_id}/learner-details",
            get(handler::get_learner_details),
        )
        .route(
            "/classes/{class_id}/students/{student_id}/learner-details",
            put(handler::upsert_learner_details),
        )
        // Attendance
        .route(
            "/classes/{class_id}/students/{student_id}/attendance",
            get(handler::get_attendance),
        )
        .route(
            "/classes/{class_id}/students/{student_id}/attendance",
            put(handler::upsert_attendance),
        )
        // Core Values
        .route(
            "/classes/{class_id}/students/{student_id}/core-values",
            get(handler::get_core_values),
        )
        .route(
            "/classes/{class_id}/students/{student_id}/core-values",
            put(handler::upsert_core_values),
        )
        // School History
        .route(
            "/classes/{class_id}/students/{student_id}/school-history",
            get(handler::get_school_history),
        )
        .route(
            "/classes/{class_id}/students/{student_id}/school-history",
            post(handler::create_school_history),
        )
        .route(
            "/classes/{class_id}/students/{student_id}/school-history/{history_id}",
            put(handler::update_school_history),
        )
        .route(
            "/classes/{class_id}/students/{student_id}/school-history/{history_id}",
            delete(handler::delete_school_history),
        )
        // Previous Subjects
        .route(
            "/classes/{class_id}/students/{student_id}/previous-subjects",
            get(handler::get_previous_subjects),
        )
        .route(
            "/classes/{class_id}/students/{student_id}/previous-subjects",
            put(handler::upsert_previous_subject),
        )
        // Previous Attendance
        .route(
            "/classes/{class_id}/students/{student_id}/previous-attendance",
            get(handler::get_previous_attendance),
        )
        .route(
            "/classes/{class_id}/students/{student_id}/previous-attendance",
            put(handler::upsert_previous_attendance),
        )
        // SF10
        .route(
            "/classes/{class_id}/students/{student_id}/sf10",
            get(handler::get_sf10),
        )
        .with_state(service)
}
