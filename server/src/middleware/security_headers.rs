use axum::{body::Body, http::Request, middleware::Next, response::Response};
use axum::http::{header, HeaderValue, HeaderName};

// HSTS is intentionally omitted — the server is HTTP-only internally.
// Nginx adds HSTS on the TLS layer. Emitting it over plain HTTP would be a no-op
// and could cause issues if the server is accessed without the proxy.
pub async fn add_security_headers(request: Request<Body>, next: Next) -> Response {
    let mut response = next.run(request).await;
    let headers = response.headers_mut();

    headers.entry(header::X_CONTENT_TYPE_OPTIONS)
        .or_insert(HeaderValue::from_static("nosniff"));

    headers.entry(header::X_FRAME_OPTIONS)
        .or_insert(HeaderValue::from_static("DENY"));

    headers.entry(header::REFERRER_POLICY)
        .or_insert(HeaderValue::from_static("strict-origin-when-cross-origin"));

    headers.entry(HeaderName::from_static("x-xss-protection"))
        .or_insert(HeaderValue::from_static("1; mode=block"));

    response
}
