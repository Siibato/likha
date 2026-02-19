use axum::{
    routing::{get, post},
    Router,
};
use std::sync::Arc;

use crate::handlers::sync_handler;
use crate::services::sync_service::SyncService;

pub fn routes(sync_service: Arc<SyncService>) -> Router {
    Router::new()
        // Public health check (no auth required)
        .route("/sync/health", get(sync_handler::health))
        // Public database ID endpoint (no auth required) - used for cache validation
        .route("/database-id", get(sync_handler::get_database_id))
        // Authenticated sync endpoints
        .route("/sync", post(sync_handler::sync))
        .route("/sync/full", post(sync_handler::full_sync))
        .route("/sync/conflicts/resolve", post(sync_handler::resolve_conflict))
        .route("/changes", get(sync_handler::get_changes))
        // Entity-specific changes endpoint (NEW)
        .route("/entities/:entity_type/:entity_id/changes", get(sync_handler::get_entity_changes))
        // Admin statistics
        .route("/sync/statistics", get(sync_handler::statistics))
        .with_state(sync_service)
}
