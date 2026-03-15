use axum::{
    routing::{delete, get, post, put},
    Router,
};
use std::sync::Arc;

use crate::handlers::assignment_handler;
use crate::services::assignment::AssignmentService;

pub fn routes(assignment_service: Arc<AssignmentService>) -> Router {
    Router::new()
        // Assignment CRUD (Teacher)
        .route(
            "/classes/{class_id}/assignments",
            post(assignment_handler::create_assignment),
        )
        .route(
            "/classes/{class_id}/assignments",
            get(assignment_handler::get_assignments),
        )
        .route(
            "/assignments/metadata",
            get(assignment_handler::get_assignments_metadata),
        )
        .route(
            "/classes/{class_id}/student-assignments",
            get(assignment_handler::get_student_assignments),
        )
        .route(
            "/assignments/{id}",
            get(assignment_handler::get_assignment_detail),
        )
        .route(
            "/assignments/{id}",
            put(assignment_handler::update_assignment),
        )
        .route(
            "/assignments/{id}",
            delete(assignment_handler::delete_assignment),
        )
        .route(
            "/assignments/{id}/publish",
            post(assignment_handler::publish_assignment),
        )
        .route(
            "/assignments/{id}/unpublish",
            post(assignment_handler::unpublish_assignment),
        )
        .route(
            "/classes/{class_id}/assignments/reorder",
            post(assignment_handler::reorder_assignments),
        )
        // Submissions (Teacher)
        .route(
            "/assignments/{id}/submissions",
            get(assignment_handler::get_submissions),
        )
        .route(
            "/assignment-submissions/{id}",
            get(assignment_handler::get_submission_detail),
        )
        .route(
            "/assignment-submissions/{id}/grade",
            post(assignment_handler::grade_submission),
        )
        .route(
            "/assignment-submissions/{id}/return",
            post(assignment_handler::return_submission),
        )
        // Student endpoints
        .route(
            "/assignments/{id}/submit",
            post(assignment_handler::create_submission),
        )
        .route(
            "/assignment-submissions/{id}/upload",
            post(assignment_handler::upload_file),
        )
        .route(
            "/submission-files/{id}",
            delete(assignment_handler::delete_submission_file),
        )
        .route(
            "/assignment-submissions/{id}/submit",
            post(assignment_handler::submit_assignment),
        )
        // File download
        .route(
            "/submission-files/{id}/download",
            get(assignment_handler::download_file),
        )
        .route(
            "/classes/{class_id}/students/{student_id}/assignment-submissions",
            get(assignment_handler::get_student_assignment_submissions),
        )
        .with_state(assignment_service)
}
