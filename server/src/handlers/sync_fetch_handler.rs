use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use std::sync::Arc;

use crate::middleware::auth_middleware::AuthUser;
use crate::schema::common::success_response;
use crate::services::sync_fetch_service::{SyncFetchService, FetchRequest};

pub async fn fetch(
    State(service): State<Arc<SyncFetchService>>,
    auth_user: AuthUser,
    Json(request): Json<FetchRequest>,
) -> impl IntoResponse {
    match service
        .fetch_records(auth_user.user_id, &auth_user.role, request)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}
