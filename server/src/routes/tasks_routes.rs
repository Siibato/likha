use axum::{routing::get, Router};
use std::sync::Arc;

use crate::handlers::tasks_handler;
use crate::services::assessment::AssessmentService;
use crate::services::assignment::AssignmentService;

#[derive(Clone)]
pub struct TasksState {
    pub assignment_service: Arc<AssignmentService>,
    pub assessment_service: Arc<AssessmentService>,
}

pub fn routes(
    assignment_service: Arc<AssignmentService>,
    assessment_service: Arc<AssessmentService>,
) -> Router {
    let state = Arc::new(TasksState {
        assignment_service,
        assessment_service,
    });
    Router::new()
        .route(
            "/classes/{class_id}/tasks",
            get(tasks_handler::get_student_tasks),
        )
        .with_state(state)
}
