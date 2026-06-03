use axum::{
    extract::FromRequestParts,
    http::{header::AUTHORIZATION, request::Parts, StatusCode},
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use std::future::Future;

use crate::utils::jwt::JwtService;

#[derive(Debug, Clone)]
pub struct AuthUser {
    pub user_id: uuid::Uuid,
    pub role: String,
}

#[derive(Debug, Serialize)]
struct AuthError {
    error: String,
    message: String,
}

impl<S> FromRequestParts<S> for AuthUser
where
    S: Send + Sync,
{
    type Rejection = Response;

    fn from_request_parts(
        parts: &mut Parts,
        _state: &S,
    ) -> impl Future<Output = Result<Self, Self::Rejection>> + Send {
        let auth_header = parts
            .headers
            .get(AUTHORIZATION)
            .and_then(|value| value.to_str().ok())
            .map(|s| s.to_string());

        async move {
            let auth_header = auth_header.ok_or_else(|| {
                (
                    StatusCode::UNAUTHORIZED,
                    Json(AuthError {
                        error: "Unauthorized".to_string(),
                        message: "Missing authorization header".to_string(),
                    }),
                )
                    .into_response()
            })?;

            let token = auth_header.strip_prefix("Bearer ").ok_or_else(|| {
                (
                    StatusCode::UNAUTHORIZED,
                    Json(AuthError {
                        error: "Unauthorized".to_string(),
                        message: "Invalid authorization header format".to_string(),
                    }),
                )
                    .into_response()
            })?;

            // Get JWT secret from environment — no fallback to prevent weak-key vulnerability
            let jwt_secret =
                std::env::var("JWT_SECRET").expect("JWT_SECRET must be set");
            let jwt_service = JwtService::new(jwt_secret, 3600);

            let claims = jwt_service.verify_token(token).map_err(|_| {
                (
                    StatusCode::UNAUTHORIZED,
                    Json(AuthError {
                        error: "Unauthorized".to_string(),
                        message: "Invalid or expired token".to_string(),
                    }),
                )
                    .into_response()
            })?;

            let user_id = uuid::Uuid::parse_str(&claims.sub).map_err(|_| {
                (
                    StatusCode::UNAUTHORIZED,
                    Json(AuthError {
                        error: "Unauthorized".to_string(),
                        message: "Invalid user ID in token".to_string(),
                    }),
                )
                    .into_response()
            })?;

            Ok(AuthUser {
                user_id,
                role: claims.role,
            })
        }
    }
}
