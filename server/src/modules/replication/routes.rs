use std::net::IpAddr;
use std::sync::Arc;

use axum::body::Body;
use axum::extract::connect_info::ConnectInfo;
use axum::http::{Request, StatusCode};
use axum::middleware::Next;
use axum::response::{IntoResponse, Response};
use axum::routing::{get, post};
use axum::{Json, Router};
use serde::Serialize;

use crate::modules::replication::handler;
use crate::modules::replication::service::ReplicationService;

pub fn routes(service: Arc<ReplicationService>) -> Router {
    Router::new()
        .route(
            "/replication/deltas",
            get(handler::get_deltas).layer(axum::middleware::from_fn(require_local_network)),
        )
        .route(
            "/replication/apply",
            post(handler::apply_deltas).layer(axum::middleware::from_fn(require_local_network)),
        )
        .with_state(service)
}

#[derive(Serialize)]
struct ErrorResponse {
    error: &'static str,
    message: &'static str,
}

async fn require_local_network(req: Request<Body>, next: Next) -> Result<Response, Response> {
    let allowed = req
        .extensions()
        .get::<ConnectInfo<std::net::SocketAddr>>()
        .map(|peer| is_local_ip(peer.0.ip()))
        .unwrap_or(false);

    if !allowed {
        let body = Json(ErrorResponse {
            error: "forbidden",
            message: "Replication endpoints are limited to RFC1918 or loopback addresses",
        });
        return Err((StatusCode::FORBIDDEN, body).into_response());
    }

    Ok(next.run(req).await)
}

fn is_local_ip(addr: IpAddr) -> bool {
    match addr {
        IpAddr::V4(v4) => {
            v4.is_loopback()
                || matches!(v4.octets(), [10, _, _, _])
                || ((v4.octets()[0] == 172) && (16..=31).contains(&v4.octets()[1]))
                || (v4.octets()[0] == 192 && v4.octets()[1] == 168)
        }
        IpAddr::V6(v6) => v6.is_loopback(),
    }
}
