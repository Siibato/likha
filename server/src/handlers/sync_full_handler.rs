use axum::{
    extract::{State, Json},
    http::StatusCode,
    response::IntoResponse,
};
use std::sync::Arc;

use crate::middleware::auth_middleware::AuthUser;
use crate::schema::common::success_response;
use crate::services::sync_full_service::{FullSyncRequest, SyncFullService};

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
