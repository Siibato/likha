use axum::{
    routing::{delete, get, post, put},
    Router,
};
use std::sync::Arc;

use crate::handlers::learning_material_handler;
use crate::services::learning_material::LearningMaterialService;

pub fn routes(material_service: Arc<LearningMaterialService>) -> Router {
    Router::new()
        // Material CRUD
        .route(
            "/classes/{class_id}/materials",
            post(learning_material_handler::create_material),
        )
        .route(
            "/classes/{class_id}/materials",
            get(learning_material_handler::get_materials),
        )
        .route(
            "/materials/metadata",
            get(learning_material_handler::get_materials_metadata),
        )
        .route(
            "/materials/{id}",
            get(learning_material_handler::get_material_detail),
        )
        .route(
            "/materials/{id}",
            put(learning_material_handler::update_material),
        )
        .route(
            "/materials/{id}",
            delete(learning_material_handler::delete_material),
        )
        .route(
            "/materials/{id}/reorder",
            post(learning_material_handler::reorder_material),
        )
        // File management
        .route(
            "/materials/{id}/files",
            post(learning_material_handler::upload_file),
        )
        .route(
            "/material-files/{file_id}",
            delete(learning_material_handler::delete_file),
        )
        .route(
            "/material-files/{file_id}/download",
            get(learning_material_handler::download_file),
        )
        .with_state(material_service)
}
