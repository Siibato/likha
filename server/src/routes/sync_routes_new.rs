use axum::{
    routing::post,
    Router,
};
use std::sync::Arc;

use crate::handlers::{
    sync_conflict_handler, sync_delta_handler, sync_full_handler,
    sync_push_handler,
};
use crate::services::{
    sync_conflict_service::SyncConflictService, sync_delta::SyncDeltaService,
    sync_full::SyncFullService,
    sync_push::SyncPushService,
};

/// Wire all sync routes and services (full/delta optimization)
pub fn routes(
    sync_push_service: Arc<SyncPushService>,
    sync_conflict_service: Arc<SyncConflictService>,
    sync_full_service: Arc<SyncFullService>,
    sync_delta_service: Arc<SyncDeltaService>,
) -> Router {
    Router::new()
        // New full/delta sync endpoints (optimized for offline-first)
        .route(
            "/sync/full",
            post(sync_full_handler::full_sync).with_state(sync_full_service),
        )
        .route(
            "/sync/deltas",
            post(sync_delta_handler::get_deltas).with_state(sync_delta_service),
        )
        .route(
            "/sync/push",
            post(sync_push_handler::push)
                .with_state(sync_push_service),
        )
        .route(
            "/sync/conflicts/resolve",
            post(sync_conflict_handler::resolve_conflict)
                .with_state(sync_conflict_service),
        )
}
