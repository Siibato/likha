use std::sync::Arc;

use axum::extract::{Query, State};
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::Json;
use serde::Deserialize;

use crate::modules::replication::auth::ReplicationAuth;
use crate::modules::replication::service::{ReplicationApplyRequest, ReplicationService};
use crate::utils::response::success_response;

#[derive(Debug, Deserialize)]
pub struct DeltaParams {
    pub since: Option<String>,
}

pub async fn get_deltas(
    Query(params): Query<DeltaParams>,
    State(service): State<Arc<ReplicationService>>,
    _auth: ReplicationAuth,
) -> impl IntoResponse {
    match service.get_deltas(params.since).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(err) => err.into_response(),
    }
}

pub async fn apply_deltas(
    State(service): State<Arc<ReplicationService>>,
    _auth: ReplicationAuth,
    Json(payload): Json<ReplicationApplyRequest>,
) -> impl IntoResponse {
    match service.apply_deltas(payload).await {
        Ok(response) => success_response(response, StatusCode::OK).into_response(),
        Err(err) => err.into_response(),
    }
}
