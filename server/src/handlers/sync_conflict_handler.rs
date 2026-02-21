use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use std::sync::Arc;

use crate::middleware::auth_middleware::AuthUser;
use crate::schema::common::success_response;
use crate::services::sync_conflict_service::{SyncConflictService, ConflictResolutionRequest};

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