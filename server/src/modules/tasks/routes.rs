use axum::{routing::get, Router};
use std::sync::Arc;

use crate::modules::tasks::handler;
use crate::modules::assessment::service::AssessmentService;
use crate::modules::assignment::service::AssignmentService;

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
            get(handler::get_student_tasks),
        )
        .with_state(state)
}
