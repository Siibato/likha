use axum::{body::Body, http::Request};
use serde_json::Value;

pub mod admin_handler_test;
pub mod assessment_handler_test;
pub mod assignment_handler_test;
pub mod auth_handler_test;
pub mod class_handler_test;
pub mod grading_handler_test;
pub mod health_handler_test;
pub mod learning_material_handler_test;
pub mod middleware;
pub mod setup_handler_test;
pub mod sync_conflict_handler_test;
pub mod sync_delta_handler_test;
pub mod sync_full_handler_test;
pub mod sync_push_handler_test;
pub mod tasks_handler_test;
pub mod tos_handler_test;

// ── Shared request/response helpers used by all handler test modules ──────────

pub fn json_req(method: &str, uri: &str, body: Option<Value>) -> Request<Body> {
    let b = body
        .map(|v| serde_json::to_string(&v).unwrap())
        .unwrap_or_default();
    Request::builder()
        .method(method)
        .uri(uri)
        .header("content-type", "application/json")
        .body(Body::from(b))
        .unwrap()
}

pub fn authed_req(method: &str, uri: &str, token: &str, body: Option<Value>) -> Request<Body> {
    let b = body
        .map(|v| serde_json::to_string(&v).unwrap())
        .unwrap_or_default();
    Request::builder()
        .method(method)
        .uri(uri)
        .header("authorization", format!("Bearer {token}"))
        .header("content-type", "application/json")
        .body(Body::from(b))
        .unwrap()
}

/// Builds a login request with ConnectInfo injected so the login handler can
/// extract the client IP address.
pub fn login_req(body: Value) -> Request<Body> {
    use axum::extract::ConnectInfo;
    use std::net::SocketAddr;

    let mut req = json_req("POST", "/api/v1/auth/login", Some(body));
    req.extensions_mut()
        .insert(ConnectInfo(SocketAddr::from(([127, 0, 0, 1], 0))));
    req
}

pub async fn body_json(resp: axum::response::Response) -> Value {
    let bytes = axum::body::to_bytes(resp.into_body(), 1024 * 1024)
        .await
        .unwrap();
    serde_json::from_slice(&bytes).unwrap_or(Value::Null)
}
