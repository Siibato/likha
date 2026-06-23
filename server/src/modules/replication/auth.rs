use axum::extract::FromRequestParts;
use axum::http::{header::AUTHORIZATION, request::Parts, StatusCode};
use axum::response::{IntoResponse, Response};
use axum::Json;
use serde::Serialize;
use std::future::Future;

#[derive(Debug, Serialize)]
struct AuthError {
    error: String,
    message: String,
}

/// Extractor that ensures replication requests include the shared secret bearer token.
pub struct ReplicationAuth;

impl<S> FromRequestParts<S> for ReplicationAuth
where
    S: Send + Sync,
{
    type Rejection = Response;

    fn from_request_parts(
        parts: &mut Parts,
        _state: &S,
    ) -> impl Future<Output = Result<Self, Self::Rejection>> + Send {
        let header = parts
            .headers
            .get(AUTHORIZATION)
            .and_then(|v| v.to_str().ok())
            .map(|s| s.to_string());

        async move {
            let header = header.ok_or_else(|| {
                (
                    StatusCode::UNAUTHORIZED,
                    Json(AuthError {
                        error: "Unauthorized".to_string(),
                        message: "Missing authorization header".to_string(),
                    }),
                )
                    .into_response()
            })?;

            let token = header.strip_prefix("Bearer ").ok_or_else(|| {
                (
                    StatusCode::UNAUTHORIZED,
                    Json(AuthError {
                        error: "Unauthorized".to_string(),
                        message: "Invalid authorization header format".to_string(),
                    }),
                )
                    .into_response()
            })?;

            let secret = std::env::var("REPLICATION_SECRET").unwrap_or_default();

            if secret.is_empty() || token != secret {
                return Err((
                    StatusCode::UNAUTHORIZED,
                    Json(AuthError {
                        error: "Unauthorized".to_string(),
                        message: "Invalid replication secret".to_string(),
                    }),
                )
                    .into_response());
            }

            Ok(ReplicationAuth)
        }
    }
}
