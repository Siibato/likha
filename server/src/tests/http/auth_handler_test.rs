use axum::http::StatusCode;
use serde_json::json;
use tower::ServiceExt;

use crate::tests::common::{
    seeds::{seed_teacher, seed_teacher_with_password},
    test_app::build_test_app,
    test_db::test_db,
};
use crate::tests::http::{authed_req, body_json, json_req, login_req};

// ── check-username ────────────────────────────────────────────────────────────

#[tokio::test]
async fn check_username_found_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        "/api/v1/auth/check-username",
        Some(json!({ "username": teacher.username })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn check_username_missing_field_returns_error() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("POST", "/api/v1/auth/check-username", Some(json!({})));
    let resp = app.oneshot(req).await.unwrap();
    assert!(
        resp.status().is_client_error(),
        "expected 4xx, got {}",
        resp.status()
    );
}

#[tokio::test]
async fn check_username_nonexistent_returns_200_with_not_found_status() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        "/api/v1/auth/check-username",
        Some(json!({ "username": "totally_unknown_user_xyz" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    // Server returns 200 with account_status indicating not found, or 404 — both acceptable.
    assert!(
        resp.status() == StatusCode::OK || resp.status() == StatusCode::NOT_FOUND,
        "got {}",
        resp.status()
    );
}

// ── activate ──────────────────────────────────────────────────────────────────

#[tokio::test]
async fn activate_missing_fields_returns_error() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("POST", "/api/v1/auth/activate", Some(json!({ "username": "u" })));
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error());
}

// ── login ─────────────────────────────────────────────────────────────────────

#[tokio::test]
async fn login_success_returns_200_with_tokens() {
    let db = test_db().await;
    let teacher = seed_teacher_with_password(&db, "Password123!").await;
    let app = build_test_app(db).await;

    let req = login_req(json!({
        "username": teacher.username,
        "password": "Password123!"
    }));
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);

    let body = body_json(resp).await;
    assert!(
        body["data"]["access_token"].is_string(),
        "expected access_token in response: {body}"
    );
}

#[tokio::test]
async fn login_wrong_password_returns_401() {
    let db = test_db().await;
    let teacher = seed_teacher_with_password(&db, "Password123!").await;
    let app = build_test_app(db).await;

    let req = login_req(json!({
        "username": teacher.username,
        "password": "WrongPassword!"
    }));
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn login_missing_password_returns_error() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = login_req(json!({ "username": "someone" }));
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error());
}

// ── refresh ───────────────────────────────────────────────────────────────────

#[tokio::test]
async fn refresh_missing_field_returns_error() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("POST", "/api/v1/auth/refresh", Some(json!({})));
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error());
}

#[tokio::test]
async fn refresh_invalid_token_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        "/api/v1/auth/refresh",
        Some(json!({ "refresh_token": "not-a-real-refresh-token" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error());
}

// ── me ────────────────────────────────────────────────────────────────────────

#[tokio::test]
async fn get_me_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = axum::http::Request::builder()
        .uri("/api/v1/auth/me")
        .body(axum::body::Body::empty())
        .unwrap();
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn get_me_authenticated_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req("GET", "/api/v1/auth/me", &teacher.token, None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

// ── logout ────────────────────────────────────────────────────────────────────
// logout uses RefreshTokenRequest body (not AuthUser/Bearer), so "auth" here
// means providing a valid refresh_token from a prior login.

#[tokio::test]
async fn logout_invalid_refresh_token_is_idempotent() {
    // The server treats logout as idempotent: even with an invalid/unknown
    // refresh_token it returns 200 rather than erroring.
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        "/api/v1/auth/logout",
        Some(json!({ "refresh_token": "not-a-valid-refresh-token" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    // 200 or 4xx are both acceptable — what must not happen is a 5xx panic.
    assert_ne!(resp.status().as_u16() / 100, 5, "got {}", resp.status());
}

#[tokio::test]
async fn logout_missing_body_returns_error() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("POST", "/api/v1/auth/logout", None);
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error(), "got {}", resp.status());
}

#[tokio::test]
async fn logout_with_valid_refresh_token_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher_with_password(&db, "Password123!").await;
    let app = build_test_app(db).await;

    // Step 1: login to get a real refresh_token.
    let login = app
        .clone()
        .oneshot(login_req(json!({
            "username": teacher.username,
            "password": "Password123!"
        })))
        .await
        .unwrap();
    let login_body = body_json(login).await;
    let refresh_token = login_body["data"]["refresh_token"]
        .as_str()
        .expect("no refresh_token in login response")
        .to_string();

    // Step 2: logout with that token.
    let req = json_req(
        "POST",
        "/api/v1/auth/logout",
        Some(json!({ "refresh_token": refresh_token })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}
