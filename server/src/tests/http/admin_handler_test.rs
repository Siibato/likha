use axum::http::StatusCode;
use serde_json::json;
use tower::ServiceExt;
use uuid::Uuid;

use crate::tests::common::{
    seeds::{seed_admin, seed_teacher},
    test_app::build_test_app,
    test_db::test_db,
};
use crate::tests::http::{authed_req, json_req};

// ── create account ────────────────────────────────────────────────────────────

#[tokio::test]
async fn create_account_as_admin_returns_201() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        "/api/v1/auth/accounts",
        &admin.token,
        Some(json!({
            "username": format!("newteacher_{}", &Uuid::new_v4().to_string()[..6]),
            "full_name": "New Teacher",
            "role": "teacher"
        })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(
        resp.status() == StatusCode::CREATED || resp.status() == StatusCode::OK,
        "got {}",
        resp.status()
    );
}

#[tokio::test]
async fn create_account_as_teacher_returns_403() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        "/api/v1/auth/accounts",
        &teacher.token,
        Some(json!({ "username": "someone", "full_name": "X", "role": "teacher" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::FORBIDDEN);
}

#[tokio::test]
async fn create_account_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        "/api/v1/auth/accounts",
        Some(json!({ "username": "u", "full_name": "U", "role": "teacher" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn create_account_missing_role_returns_error() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        "/api/v1/auth/accounts",
        &admin.token,
        Some(json!({ "username": "u", "full_name": "U" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error());
}

// ── list accounts ─────────────────────────────────────────────────────────────

#[tokio::test]
async fn list_accounts_as_admin_returns_200() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req("GET", "/api/v1/auth/accounts", &admin.token, None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn list_accounts_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("GET", "/api/v1/auth/accounts", None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── get account by id ─────────────────────────────────────────────────────────

#[tokio::test]
async fn get_account_by_id_returns_200() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/auth/accounts/{}", teacher.id),
        &admin.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn get_account_nonexistent_returns_404() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/auth/accounts/{}", Uuid::new_v4()),
        &admin.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

#[tokio::test]
async fn get_account_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "GET",
        &format!("/api/v1/auth/accounts/{}", Uuid::new_v4()),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── update account ────────────────────────────────────────────────────────────

#[tokio::test]
async fn update_account_as_admin_returns_200() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "PUT",
        &format!("/api/v1/auth/accounts/{}", teacher.id),
        &admin.token,
        Some(json!({ "full_name": "Updated Name" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn update_nonexistent_account_returns_404() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "PUT",
        &format!("/api/v1/auth/accounts/{}", Uuid::new_v4()),
        &admin.token,
        Some(json!({ "full_name": "Ghost" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

// ── reset account ─────────────────────────────────────────────────────────────

#[tokio::test]
async fn reset_account_as_admin_returns_200() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        "/api/v1/auth/accounts/reset",
        &admin.token,
        Some(json!({ "user_id": teacher.id })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn reset_account_as_teacher_returns_403() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        "/api/v1/auth/accounts/reset",
        &teacher.token,
        Some(json!({ "user_id": teacher.id })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::FORBIDDEN);
}

// ── lock account ──────────────────────────────────────────────────────────────

#[tokio::test]
async fn lock_account_as_admin_returns_200() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        "/api/v1/auth/accounts/lock",
        &admin.token,
        Some(json!({ "user_id": teacher.id, "locked": true })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

// ── delete account ────────────────────────────────────────────────────────────

#[tokio::test]
async fn delete_account_as_admin_returns_200() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "DELETE",
        &format!("/api/v1/auth/accounts/{}", teacher.id),
        &admin.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn delete_nonexistent_account_returns_404() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "DELETE",
        &format!("/api/v1/auth/accounts/{}", Uuid::new_v4()),
        &admin.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

// ── activity logs ─────────────────────────────────────────────────────────────

#[tokio::test]
async fn get_activity_logs_as_admin_returns_200() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/auth/accounts/{}/logs", teacher.id),
        &admin.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn get_activity_logs_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "GET",
        &format!("/api/v1/auth/accounts/{}/logs", Uuid::new_v4()),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}
