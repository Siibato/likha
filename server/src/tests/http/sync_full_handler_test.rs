use axum::http::StatusCode;
use serde_json::json;
use tower::ServiceExt;

use crate::tests::common::{
    seeds::seed_teacher,
    test_app::build_test_app,
    test_db::test_db,
};
use crate::tests::http::{authed_req, json_req};

#[tokio::test]
async fn sync_full_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("POST", "/api/v1/sync/full", Some(json!({})));
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn sync_full_authenticated_returns_success() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    // FullSyncRequest requires device_id.
    let req = authed_req(
        "POST",
        "/api/v1/sync/full",
        &teacher.token,
        Some(json!({ "device_id": "test-device-001" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(
        resp.status().is_success(),
        "expected 2xx, got {}",
        resp.status()
    );
}

#[tokio::test]
async fn sync_full_returns_structured_payload() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        "/api/v1/sync/full",
        &teacher.token,
        Some(json!({ "device_id": "test-device-001" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);

    let body = crate::tests::http::body_json(resp).await;
    assert!(body.is_object() || body["data"].is_object(), "body: {body}");
}
