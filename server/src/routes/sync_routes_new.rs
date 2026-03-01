use axum::{
    routing::post,
    Router,
};
use std::sync::Arc;

use crate::handlers::{
    sync_conflict_handler, sync_delta_handler, sync_fetch_handler, sync_full_handler,
    sync_manifest_handler, sync_push_handler,
};
use crate::services::{
    sync_conflict_service::SyncConflictService, sync_delta_service::SyncDeltaService,
    sync_fetch_service::SyncFetchService, sync_full_service::SyncFullService,
    sync_manifest_service::SyncManifestService, sync_push_service::SyncPushService,
};

/// Wire all sync routes and services (manifest-driven + full/delta)
pub fn routes(
    sync_manifest_service: Arc<SyncManifestService>,
    sync_fetch_service: Arc<SyncFetchService>,
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
        // Legacy manifest-driven sync endpoints (kept for backward compatibility)
        .route(
            "/sync/manifest",
            post(sync_manifest_handler::manifest)
                .with_state(sync_manifest_service),
        )
        .route(
            "/sync/fetch",
            post(sync_fetch_handler::fetch)
                .with_state(sync_fetch_service),
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
