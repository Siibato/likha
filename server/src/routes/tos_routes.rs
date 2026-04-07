use axum::{
    routing::{delete, get, post, put},
    Router,
};
use std::sync::Arc;

use crate::handlers::tos_handler;
use crate::services::tos::TosService;

pub fn routes(tos_service: Arc<TosService>) -> Router {
    Router::new()
        // TOS CRUD
        .route(
            "/classes/{class_id}/tos",
            get(tos_handler::list_tos).post(tos_handler::create_tos),
        )
        .route(
            "/tos/{id}",
            get(tos_handler::get_tos)
                .put(tos_handler::update_tos)
                .delete(tos_handler::delete_tos),
        )
        // Competencies
        .route(
            "/tos/{tos_id}/competencies",
            post(tos_handler::add_competency),
        )
        .route(
            "/tos/competencies/{id}",
            put(tos_handler::update_competency).delete(tos_handler::delete_competency),
        )
        .route(
            "/tos/{tos_id}/competencies/bulk",
            post(tos_handler::bulk_add_competencies),
        )
        // MELCS Search
        .route("/melcs", get(tos_handler::search_melcs))
        .with_state(tos_service)
}
