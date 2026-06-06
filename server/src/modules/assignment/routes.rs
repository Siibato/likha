use axum::{
    extract::DefaultBodyLimit,
    routing::{delete, get, post, put},
    Router,
};
use std::sync::Arc;

use crate::modules::assignment::handler;
use crate::modules::assignment::service::AssignmentService;

pub fn routes(assignment_service: Arc<AssignmentService>) -> Router {
    Router::new()
        // Assignment CRUD (Teacher)
        .route(
            "/classes/{class_id}/assignments",
            post(handler::create_assignment),
        )
        .route(
            "/classes/{class_id}/assignments",
            get(handler::get_assignments),
        )
        .route(
            "/classes/{class_id}/assignments/metadata",
            get(handler::get_assignments_metadata),
        )
        .route(
            "/student-assignments",
            get(handler::get_student_assignments),
        )
        .route(
            "/assignments/{id}",
            get(handler::get_assignment_detail),
        )
        .route(
            "/assignments/{id}",
            put(handler::update_assignment),
        )
        .route(
            "/assignments/{id}",
            delete(handler::delete_assignment),
        )
        .route(
            "/assignments/{id}/publish",
            post(handler::publish_assignment),
        )
        .route(
            "/assignments/{id}/unpublish",
            post(handler::unpublish_assignment),
        )
        .route(
            "/classes/{class_id}/assignments/reorder",
            post(handler::reorder_assignments),
        )
        // Submissions (Teacher)
        .route(
            "/assignments/{id}/submissions",
            get(handler::get_submissions),
        )
        .route(
            "/assignment-submissions/{id}",
            get(handler::get_submission_detail),
        )
        .route(
            "/assignment-submissions/{id}/grade",
            post(handler::grade_submission),
        )
        .route(
            "/assignment-submissions/{id}/return",
            post(handler::return_submission),
        )
        // Student endpoints
        .route(
            "/assignments/{id}/submit",
            post(handler::create_submission),
        )
        .route(
            "/assignment-submissions/{id}/upload",
            post(handler::upload_file)
                .layer(DefaultBodyLimit::max(50 * 1024 * 1024)),
        )
        .route(
            "/submission-files/{id}",
            delete(handler::delete_submission_file),
        )
        .route(
            "/assignment-submissions/{id}/submit",
            post(handler::submit_assignment),
        )
        // File download
        .route(
            "/submission-files/{id}/download",
            get(handler::download_file),
        )
        .route(
            "/assignments/{assignment_id}/students/{student_id}/submissions",
            get(handler::get_student_assignment_submissions),
        )
        .with_state(assignment_service)
}
