use axum::extract::Extension;
use axum::http::StatusCode;
use axum::Json;
use chrono::Utc;
use serde_json::json;
use std::sync::Arc;

use crate::middleware::auth_middleware::Claims;
use crate::schema::sync_schema::*;
use crate::services::sync_service::SyncService;

/// POST /api/sync
/// Client sends offline changes to be synced
/// Returns results of each operation + cache updates
pub async fn sync(
    Extension(claims): Extension<Claims>,
    Extension(sync_service): Extension<Arc<SyncService>>,
    Json(request): Json<SyncRequest>,
) -> Result<(StatusCode, Json<SyncResponse>), (StatusCode, String)> {
    tracing::info!("Sync request from user: {}", claims.sub);

    let response = sync_service
        .sync(claims.sub.clone(), request)
        .await
        .map_err(|e| {
            tracing::error!("Sync error: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("Sync failed: {}", e),
            )
        })?;

    Ok((StatusCode::OK, Json(response)))
}

/// POST /api/sync/full
/// Client requests full cache refresh (when recovering from major issues)
pub async fn full_sync(
    Extension(claims): Extension<Claims>,
    Extension(sync_service): Extension<Arc<SyncService>>,
    Json(request): Json<FullSyncRequest>,
) -> Result<(StatusCode, Json<FullSyncResponse>), (StatusCode, String)> {
    tracing::info!("Full sync request from user: {}", claims.sub);

    let response = sync_service
        .full_sync(claims.sub.clone(), request)
        .await
        .map_err(|e| {
            tracing::error!("Full sync error: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("Full sync failed: {}", e),
            )
        })?;

    Ok((StatusCode::OK, Json(response)))
}

/// GET /api/sync/health
/// Check if sync system is operational
pub async fn health(
    Extension(sync_service): Extension<Arc<SyncService>>,
) -> Result<(StatusCode, Json<SyncHealthResponse>), (StatusCode, String)> {
    let response = sync_service.health_check().await.map_err(|e| {
        tracing::error!("Health check error: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Health check failed: {}", e),
        )
    })?;

    Ok((StatusCode::OK, Json(response)))
}

/// POST /api/sync/conflict-resolution
/// Client sends conflict resolution
pub async fn resolve_conflict(
    Extension(claims): Extension<Claims>,
    Json(request): Json<ConflictResolutionRequest>,
) -> Result<(StatusCode, Json<ConflictResolutionResponse>), (StatusCode, String)> {
    tracing::info!(
        "Conflict resolution from user {}: entity_type={}, entity_id={}",
        claims.sub,
        request.entity_type,
        request.entity_id
    );

    // In production, would implement actual conflict resolution logic
    // For now, server wins by default
    let response = ConflictResolutionResponse {
        success: true,
        message: Some("Conflict resolved using server-wins strategy".to_string()),
        updated_entity: Some(json!({})),
    };

    Ok((StatusCode::OK, Json(response)))
}

/// GET /api/sync/statistics
/// Get sync system statistics (admin only)
pub async fn statistics(
    Extension(claims): Extension<Claims>,
    Extension(sync_service): Extension<Arc<SyncService>>,
) -> Result<(StatusCode, Json<SyncStatistics>), (StatusCode, String)> {
    // Verify user is admin
    if claims.role != "admin" {
        return Err((
            StatusCode::FORBIDDEN,
            "Only admins can view sync statistics".to_string(),
        ));
    }

    let stats = sync_service.get_statistics();
    Ok((StatusCode::OK, Json(stats)))
}
