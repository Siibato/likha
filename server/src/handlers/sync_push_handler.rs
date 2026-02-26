use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use std::sync::Arc;

use crate::middleware::auth_middleware::AuthUser;
use crate::schema::common::success_response;
use crate::services::sync_push_service::SyncPushService;

pub async fn push(
    State(service): State<Arc<SyncPushService>>,
    auth_user: AuthUser,
    Json(payload): Json<serde_json::Value>,
) -> impl IntoResponse {
    match service
        .push_operations(auth_user.user_id, &auth_user.role, payload)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}
