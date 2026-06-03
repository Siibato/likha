use axum::{
    routing::{delete, get, post, put},
    Router,
};
use std::sync::Arc;

use crate::modules::class::handler;
use crate::modules::class::service::ClassService;

pub fn routes(class_service: Arc<ClassService>) -> Router {
    Router::new()
        .route("/classes", post(handler::create_class))
        .route("/classes", get(handler::get_classes))
        .route("/classes/metadata", get(handler::get_classes_metadata))
        .route("/classes/{id}", get(handler::get_class_detail))
        .route("/classes/{id}", put(handler::update_class))
        .route("/classes/{id}", delete(handler::delete_class))
        .route(
            "/classes/{id}/students",
            post(handler::add_student),
        )
        .route(
            "/classes/{id}/students/{student_id}",
            delete(handler::remove_student),
        )
        .with_state(class_service)
}
