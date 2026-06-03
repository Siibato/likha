use axum::{
    routing::post,
    Router,
};
use std::sync::Arc;

use crate::modules::sync::handler;
use crate::modules::sync::service_operations::push::SyncPushService;
use crate::modules::sync::service_operations::delta::SyncDeltaService;
use crate::modules::sync::service_operations::full::SyncFullService;
use crate::modules::sync::service_operations::conflict_service::SyncConflictService;

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
            post(handler::full_sync).with_state(sync_full_service),
        )
        .route(
            "/sync/deltas",
            post(handler::get_deltas).with_state(sync_delta_service),
        )
        .route(
            "/sync/push",
            post(handler::push)
                .with_state(sync_push_service),
        )
        .route(
            "/sync/conflicts/resolve",
            post(handler::resolve_conflict)
                .with_state(sync_conflict_service),
        )
}
