use axum::{
    extract::State,
    extract::Json,
    http::StatusCode,
    response::IntoResponse,
};
use std::sync::Arc;

use crate::middleware::auth_middleware::AuthUser;
use crate::utils::response::success_response;
use crate::modules::sync::service::{SyncPushService, SyncDeltaService, SyncFullService, SyncConflictService};
use crate::modules::sync::schema::{DeltaRequest, FullSyncRequest, ConflictResolutionRequest};

/// POST /sync/push - Push sync operations
pub async fn push(
    State(service): State<Arc<SyncPushService>>,
    auth_user: AuthUser,
    Json(payload): Json<serde_json::Value>,
) -> impl IntoResponse {
    let op_count = payload.get("operations")
        .and_then(|ops| ops.as_array())
        .map(|arr| arr.len())
        .unwrap_or(0);

    tracing::info!(
        "Push sync initiated for user_id={}, role={}, operation_count={}",
        auth_user.user_id,
        auth_user.role,
        op_count
    );

    match service
        .push_operations(auth_user.user_id, &auth_user.role, payload)
        .await
    {
        Ok(response) => {
            let success_count = response.results.iter().filter(|r| r.success).count();
            let failed_count = response.results.len() - success_count;

            tracing::info!(
                "Push sync completed for user_id={}: total={}, success={}, failed={}",
                auth_user.user_id,
                response.results.len(),
                success_count,
                failed_count
            );

            success_response(response, StatusCode::OK).into_response()
        }
        Err(e) => {
            tracing::error!(
                "Push sync failed for user_id={}: {:?}",
                auth_user.user_id,
                e
            );
            e.into_response()
        }
    }
}

/// POST /sync/deltas - Delta sync on app restart
pub async fn get_deltas(
    State(service): State<Arc<SyncDeltaService>>,
    auth_user: AuthUser,
    Json(request): Json<DeltaRequest>,
) -> impl IntoResponse {
    match service
        .get_deltas(auth_user.user_id, &auth_user.role, request)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

/// POST /sync/full - Full sync on login
pub async fn full_sync(
    State(service): State<Arc<SyncFullService>>,
    auth_user: AuthUser,
    Json(request): Json<FullSyncRequest>,
) -> impl IntoResponse {
    tracing::info!(
        "Full sync initiated for user_id={}, role={}, device_id={}",
        auth_user.user_id,
        auth_user.role,
        request.device_id
    );

    match service
        .get_full_sync(auth_user.user_id, &auth_user.role, request)
        .await
    {
        Ok(response) => {
            tracing::info!(
                "Full sync completed successfully for user_id={}. Classes: {}, Enrollments: {}, Assessments: {}, Assignments: {}",
                auth_user.user_id,
                response.classes.len(),
                response.enrollments.len(),
                response.assessments.len(),
                response.assignments.len()
            );
            success_response(response, StatusCode::OK).into_response()
        }
        Err(e) => {
            tracing::error!(
                "Full sync failed for user_id={}: {:?}",
                auth_user.user_id,
                e
            );
            e.into_response()
        }
    }
}

/// POST /sync/conflicts/resolve - Resolve sync conflicts
pub async fn resolve_conflict(
    State(service): State<Arc<SyncConflictService>>,
    _auth_user: AuthUser,
    Json(request): Json<ConflictResolutionRequest>,
) -> impl IntoResponse {
    match service
        .resolve_conflict(&request.conflict_id, &request.resolution)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}

