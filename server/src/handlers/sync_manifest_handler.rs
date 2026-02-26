use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
};
use std::sync::Arc;

use crate::middleware::auth_middleware::AuthUser;
use crate::schema::common::success_response;
use crate::services::sync_manifest_service::SyncManifestService;

pub async fn manifest(
    State(service): State<Arc<SyncManifestService>>,
    auth_user: AuthUser,
) -> impl IntoResponse {
    match service
        .get_manifest(auth_user.user_id, &auth_user.role)
        .await
    {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(e) => e.into_response(),
    }
}
