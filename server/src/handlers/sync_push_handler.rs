use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use std::sync::Arc;

use crate::middleware::auth_middleware::AuthUser;
use crate::schema::common::success_response;
use crate::services::sync_push::SyncPushService;

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
