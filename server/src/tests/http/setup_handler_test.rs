use axum::http::StatusCode;
use serde_json::json;
use tower::ServiceExt;

use crate::tests::common::{
    seeds::{seed_admin, seed_student},
    test_app::build_test_app,
    test_db::test_db,
};
use crate::tests::http::{authed_req, json_req};

// ── verify_code (public) ──────────────────────────────────────────────────────

#[tokio::test]
async fn verify_code_with_valid_code_returns_200() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    // build_test_app seeds SetupService with "TEST-CODE"
    let req = json_req("GET", "/api/v1/setup/verify?code=TEST-CODE", None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn verify_code_with_wrong_code_returns_error() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("GET", "/api/v1/setup/verify?code=WRONG-CODE", None);
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error(), "got {}", resp.status());
}

// ── get_school_info (public) ──────────────────────────────────────────────────

#[tokio::test]
async fn get_school_info_returns_200_no_auth() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("GET", "/api/v1/setup/info", None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

// ── get_qr_code (admin) ───────────────────────────────────────────────────────

#[tokio::test]
async fn get_qr_code_as_admin_returns_200() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req("GET", "/api/v1/admin/setup/qr", &admin.token, None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn get_qr_code_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("GET", "/api/v1/admin/setup/qr", None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn get_qr_code_as_student_returns_403() {
    let db = test_db().await;
    let student = seed_student(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req("GET", "/api/v1/admin/setup/qr", &student.token, None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::FORBIDDEN);
}

// ── get_school_code (admin) ───────────────────────────────────────────────────

#[tokio::test]
async fn get_school_code_as_admin_returns_200() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req("GET", "/api/v1/admin/setup/code", &admin.token, None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn get_school_code_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("GET", "/api/v1/admin/setup/code", None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── update_school_code (admin) ────────────────────────────────────────────────

#[tokio::test]
async fn update_school_code_as_admin_returns_200() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "PUT",
        "/api/v1/admin/setup/code",
        &admin.token,
        Some(json!({ "code": "ABCD12" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn update_school_code_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "PUT",
        "/api/v1/admin/setup/code",
        Some(json!({ "code": "ABCD12" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn update_school_code_missing_field_returns_error() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "PUT",
        "/api/v1/admin/setup/code",
        &admin.token,
        Some(json!({})),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error(), "got {}", resp.status());
}

#[tokio::test]
async fn update_school_code_as_student_returns_403() {
    let db = test_db().await;
    let student = seed_student(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "PUT",
        "/api/v1/admin/setup/code",
        &student.token,
        Some(json!({ "code": "ABCD12" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::FORBIDDEN);
}

// ── get_school_settings (admin) ───────────────────────────────────────────────

#[tokio::test]
async fn get_school_settings_as_admin_returns_200() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req("GET", "/api/v1/admin/setup/school-settings", &admin.token, None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn get_school_settings_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("GET", "/api/v1/admin/setup/school-settings", None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── update_school_settings (admin) ────────────────────────────────────────────

#[tokio::test]
async fn update_school_settings_as_admin_returns_200() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "PUT",
        "/api/v1/admin/setup/school-settings",
        &admin.token,
        Some(json!({
            "school_name": "Test School",
            "school_region": "Region IV",
            "school_division": "Division A",
            "school_year": "2024-2025"
        })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn update_school_settings_missing_required_field_returns_error() {
    let db = test_db().await;
    let admin = seed_admin(&db).await;
    let app = build_test_app(db).await;

    // school_name is required
    let req = authed_req(
        "PUT",
        "/api/v1/admin/setup/school-settings",
        &admin.token,
        Some(json!({ "school_region": "Region IV" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error(), "got {}", resp.status());
}

#[tokio::test]
async fn update_school_settings_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "PUT",
        "/api/v1/admin/setup/school-settings",
        Some(json!({ "school_name": "Test School" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn update_school_settings_as_student_returns_403() {
    let db = test_db().await;
    let student = seed_student(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "PUT",
        "/api/v1/admin/setup/school-settings",
        &student.token,
        Some(json!({ "school_name": "Test School" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::FORBIDDEN);
}
