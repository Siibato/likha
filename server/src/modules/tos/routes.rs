use axum::{
    routing::{get, post, put},
    Router,
};
use std::sync::Arc;

use crate::modules::tos::handler;
use crate::modules::tos::service::TosService;

pub fn routes(tos_service: Arc<TosService>) -> Router {
    Router::new()
        // TOS CRUD
        .route(
            "/classes/{class_id}/tos",
            get(handler::list_tos).post(handler::create_tos),
        )
        .route(
            "/tos/{id}",
            get(handler::get_tos)
                .put(handler::update_tos)
                .delete(handler::delete_tos),
        )
        // Competencies
        .route(
            "/tos/{tos_id}/competencies",
            post(handler::add_competency),
        )
        .route(
            "/tos/competencies/{id}",
            put(handler::update_competency).delete(handler::delete_competency),
        )
        .route(
            "/tos/{tos_id}/competencies/bulk",
            post(handler::bulk_add_competencies),
        )
        // MELCS Search
        .route("/melcs", get(handler::search_melcs))
        .with_state(tos_service)
}
