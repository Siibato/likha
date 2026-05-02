use std::net::SocketAddr;

use axum::extract::ConnectInfo;
use axum::http::{Extensions, HeaderMap, header::AUTHORIZATION};

use crate::utils::jwt::JwtService;

/// Builds a rate limit key from the request context.
///
/// For authenticated requests: `uid:{user_id}:dev:{device_id}`
/// For unauthenticated requests: `ip:{client_ip}:dev:{device_id}`
///
/// The X-Device-ID header identifies the device. Falls back to "unknown" if absent.
/// JWT decoding is best-effort — failures silently fall through to IP-based keying.
pub fn extract_key(headers: &HeaderMap, extensions: &Extensions, jwt_secret: &str) -> String {
    let device_id = headers
        .get("X-Device-ID")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("unknown");

    if let Some(user_id) = try_extract_user_id(headers, jwt_secret) {
        return format!("uid:{}:dev:{}", user_id, device_id);
    }

    let ip = extensions
        .get::<ConnectInfo<SocketAddr>>()
        .map(|ci| ci.0.ip().to_string())
        .unwrap_or_else(|| "unknown".to_string());

    format!("ip:{}:dev:{}", ip, device_id)
}

fn try_extract_user_id(headers: &HeaderMap, jwt_secret: &str) -> Option<String> {
    let auth_value = headers.get(AUTHORIZATION)?.to_str().ok()?;
    let token = auth_value.strip_prefix("Bearer ")?;
    JwtService::new(jwt_secret.to_string(), 3600)
        .verify_token(token)
        .ok()
        .map(|claims| claims.sub)
}
