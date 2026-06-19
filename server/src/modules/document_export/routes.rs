use std::sync::Arc;

use axum::Router;

use crate::modules::document_export::handler;
use crate::modules::document_export::service::DocumentExportService;

pub fn routes(service: Arc<DocumentExportService>) -> Router {
    Router::new()
        .route(
            "/classes/{class_id}/export/grades-pdf",
            axum::routing::get(handler::export_class_grades_pdf),
        )
        .route(
            "/classes/{class_id}/export/grades-excel",
            axum::routing::get(handler::export_class_grades_excel),
        )
        .route(
            "/classes/{class_id}/export/sf9/{student_id}",
            axum::routing::get(handler::export_sf9_pdf),
        )
        .with_state(service)
}
