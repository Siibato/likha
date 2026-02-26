use axum::{
    routing::post,
    Router,
};
use std::sync::Arc;

use crate::handlers::{
    sync_conflict_handler, sync_fetch_handler, sync_manifest_handler,
    sync_push_handler,
};
use crate::services::{
    sync_conflict_service::SyncConflictService, sync_fetch_service::SyncFetchService,
    sync_manifest_service::SyncManifestService, sync_push_service::SyncPushService,
};

/// Wire all new manifest-driven sync routes and services
pub fn routes(
    sync_manifest_service: Arc<SyncManifestService>,
    sync_fetch_service: Arc<SyncFetchService>,
    sync_push_service: Arc<SyncPushService>,
    sync_conflict_service: Arc<SyncConflictService>,
) -> Router {
    Router::new()
        // New manifest-driven sync endpoints
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
