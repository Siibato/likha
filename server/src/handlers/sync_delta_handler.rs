use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use std::sync::Arc;

use crate::middleware::auth_middleware::AuthUser;
use crate::schema::common::success_response;
use crate::services::sync_delta_service::{DeltaRequest, SyncDeltaService};

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
