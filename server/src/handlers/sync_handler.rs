use axum::{
    extract::{State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use sea_orm::EntityTrait;
use std::sync::Arc;

use crate::middleware::auth_middleware::AuthUser;
use crate::schema::sync_schema::*;
use crate::schema::common::success_response;
use crate::services::sync_service::SyncService;
use crate::utils::error::AppError;
use entity::database_metadata;

/// POST /api/sync
/// Client sends offline changes to be synced
/// Returns results of each operation + cache updates
pub async fn sync(
    State(sync_service): State<Arc<SyncService>>,
    auth_user: AuthUser,
    Json(request): Json<SyncRequest>,
) -> impl IntoResponse {
    tracing::info!("Sync request from user: {}", auth_user.user_id);

    match sync_service
        .sync(auth_user.user_id.to_string(), request)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => {
            tracing::error!("Sync error: {}", e);
            AppError::InternalServerError(format!("Sync failed: {}", e)).into_response()
        }
    }
}

/// POST /api/sync/full
/// Client requests full cache refresh (when recovering from major issues)
pub async fn full_sync(
    State(sync_service): State<Arc<SyncService>>,
    auth_user: AuthUser,
    Json(request): Json<FullSyncRequest>,
) -> impl IntoResponse {
    tracing::info!("Full sync request from user: {}", auth_user.user_id);

    match sync_service
        .full_sync(auth_user.user_id.to_string(), request)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => {
            tracing::error!("Full sync error: {}", e);
            AppError::InternalServerError(format!("Full sync failed: {}", e)).into_response()
        }
    }
}

/// GET /api/sync/health
/// Check if sync system is operational
pub async fn health(
    State(sync_service): State<Arc<SyncService>>,
) -> impl IntoResponse {
    match sync_service.health_check().await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => {
            tracing::error!("Health check error: {}", e);
            AppError::InternalServerError(format!("Health check failed: {}", e)).into_response()
        }
    }
}

/// POST /api/sync/conflict-resolution
/// Client sends conflict resolution
pub async fn resolve_conflict(
    State(sync_service): State<Arc<SyncService>>,
    auth_user: AuthUser,
    Json(request): Json<ConflictResolutionRequest>,
) -> impl IntoResponse {
    tracing::info!(
        "Conflict resolution from user {}: entity_type={}, entity_id={}, resolution={}",
        auth_user.user_id,
        request.entity_type,
        request.entity_id,
        request.resolution
    );

    match sync_service
        .resolve_conflict(&auth_user.user_id.to_string(), request)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => {
            tracing::error!("Conflict resolution error: {}", e);
            AppError::InternalServerError(format!("Conflict resolution failed: {}", e)).into_response()
        }
    }
}

/// GET /api/sync/statistics
/// Get sync system statistics (admin only)
pub async fn statistics(
    State(sync_service): State<Arc<SyncService>>,
    auth_user: AuthUser,
) -> impl IntoResponse {
    // Verify user is admin
    if auth_user.role != "admin" {
        return AppError::Forbidden("Only admins can view sync statistics".to_string()).into_response();
    }

    let stats = sync_service.get_statistics();
    success_response(stats, StatusCode::OK).into_response()
}

pub async fn get_database_id(
    State(sync_service): State<Arc<SyncService>>,
) -> impl IntoResponse {
    match sync_service.get_database_id().await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => {
            tracing::error!("Error fetching database ID: {}", e);
            AppError::InternalServerError(format!("Failed to retrieve database ID: {}", e))
                .into_response()
        }
    }
}

/// GET /api/v1/changes
/// Get incremental changes since last sync
pub async fn get_changes(
    State(sync_service): State<Arc<SyncService>>,
    auth_user: AuthUser,
    axum::extract::Query(params): axum::extract::Query<ChangesQueryParams>,
) -> impl IntoResponse {
    tracing::info!(
        "Get changes request from user: {}, since_sequence: {}",
        auth_user.user_id,
        params.since_sequence
    );

    match sync_service.get_changes(params).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => {
            tracing::error!("Get changes error: {}", e);
            AppError::InternalServerError(format!("Get changes failed: {}", e)).into_response()
        }
    }
}

/// GET /api/v1/entities/:entity_type/:entity_id/changes
/// Get all changes for a specific entity since a timestamp
pub async fn get_entity_changes(
    State(sync_service): State<Arc<SyncService>>,
    auth_user: AuthUser,
    axum::extract::Path((entity_type, entity_id)): axum::extract::Path<(String, String)>,
    axum::extract::Query(params): axum::extract::Query<EntityChangesQueryParams>,
) -> impl IntoResponse {
    tracing::info!(
        "Get entity changes request from user: {}, entity_type: {}, entity_id: {}",
        auth_user.user_id,
        entity_type,
        entity_id
    );

    match sync_service
        .get_entity_changes(&entity_type, &entity_id, params.since, params.limit)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => {
            tracing::error!("Get entity changes error: {}", e);
            AppError::InternalServerError(format!("Get entity changes failed: {}", e)).into_response()
        }
    }
}
