use axum::{
    extract::State,
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
) -> impl IntoResponse {
    match service
        .get_full_sync(auth_user.user_id, &auth_user.role, FullSyncRequest {
            device_id: String::new(),
        })
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}
