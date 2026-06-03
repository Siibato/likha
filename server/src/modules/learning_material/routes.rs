use axum::{
    extract::DefaultBodyLimit,
    routing::{delete, get, post, put},
    Router,
};
use std::sync::Arc;

use crate::modules::learning_material::handler;
use crate::modules::learning_material::service::LearningMaterialService;

pub fn routes(material_service: Arc<LearningMaterialService>) -> Router {
    Router::new()
        // Material CRUD
        .route(
            "/classes/{class_id}/materials",
            post(handler::create_material),
        )
        .route(
            "/classes/{class_id}/materials",
            get(handler::get_materials),
        )
        .route(
            "/materials/metadata",
            get(handler::get_materials_metadata),
        )
        .route(
            "/materials/{id}",
            get(handler::get_material_detail),
        )
        .route(
            "/materials/{id}",
            put(handler::update_material),
        )
        .route(
            "/materials/{id}",
            delete(handler::delete_material),
        )
        .route(
            "/materials/{id}/reorder",
            post(handler::reorder_material),
        )
        .route(
            "/classes/{class_id}/materials/reorder",
            post(handler::reorder_materials),
        )
        // File management
        .route(
            "/materials/{id}/files",
            post(handler::upload_file)
                .layer(DefaultBodyLimit::max(50 * 1024 * 1024)),
        )
        .route(
            "/material-files/{file_id}",
            delete(handler::delete_file),
        )
        .route(
            "/material-files/{file_id}/download",
            get(handler::download_file),
        )
        .with_state(material_service)
}
