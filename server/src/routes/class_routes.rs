use axum::{
    routing::{delete, get, post},
    Router,
};
use std::sync::Arc;

use crate::handlers::class_handler;
use crate::services::auth_service::AuthService;
use crate::services::class_service::ClassService;

pub fn routes(class_service: Arc<ClassService>, auth_service: Arc<AuthService>) -> Router {
    let class_routes = Router::new()
        .route("/classes", post(class_handler::create_class))
        .route("/classes", get(class_handler::get_classes))
        .route("/classes/{id}", get(class_handler::get_class_detail))
        .route(
            "/classes/{id}/students",
            post(class_handler::add_student),
        )
        .route(
            "/classes/{id}/students/{student_id}",
            delete(class_handler::remove_student),
        )
        .with_state(class_service);

    let search_routes = Router::new()
        .route("/students/search", get(class_handler::search_students))
        .with_state(auth_service);

    class_routes.merge(search_routes)
}
