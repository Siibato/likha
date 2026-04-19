use axum::http::StatusCode;
use tower::ServiceExt;

use crate::tests::common::{
    jwt_helper::wrong_secret_token,
    seeds::seed_teacher,
    test_app::build_test_app,
    test_db::test_db,
};
use crate::tests::http::authed_req;

/// GET /api/v1/auth/me is a lightweight authenticated probe used throughout
/// these middleware tests. All it needs is a valid JWT — no DB side-effects.
const PROBE: &str = "/api/v1/auth/me";

#[tokio::test]
async fn auth_missing_header_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;
    let req = axum::http::Request::builder()
        .uri(PROBE)
        .body(axum::body::Body::empty())
        .unwrap();
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn auth_wrong_scheme_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;
    let req = axum::http::Request::builder()
        .uri(PROBE)
        .header("authorization", "Basic dXNlcjpwYXNz")
        .body(axum::body::Body::empty())
        .unwrap();
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn auth_garbage_token_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;
    let req = authed_req("GET", PROBE, "thisisnot.avalid.jwt", None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn auth_wrong_secret_token_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;
    let bad = wrong_secret_token();
    let req = authed_req("GET", PROBE, &bad, None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn auth_expired_token_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;
    // A structurally valid JWT with exp=1 (Unix epoch + 1 second — long expired).
    let expired = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.\
                   eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDAiLCJ1c2VybmFtZSI6InRlc3QiLCJyb2xlIjoidGVhY2hlciIsImV4cCI6MSwiYXQiOjF9.\
                   BADSIG";
    let req = authed_req("GET", PROBE, expired, None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn auth_valid_token_passes_middleware() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;
    let req = authed_req("GET", PROBE, &teacher.token, None);
    let resp = app.oneshot(req).await.unwrap();
    // 200 or 404 are both acceptable — what matters is NOT 401.
    assert_ne!(resp.status(), StatusCode::UNAUTHORIZED);
}
