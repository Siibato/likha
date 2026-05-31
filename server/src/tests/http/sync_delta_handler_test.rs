use axum::http::StatusCode;
use serde_json::json;
use tower::ServiceExt;

use crate::tests::common::{
    seeds::seed_teacher,
    test_app::build_test_app,
    test_db::test_db,
};
use crate::tests::http::{authed_req, body_json, json_req};

#[tokio::test]
async fn sync_deltas_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("POST", "/api/v1/sync/deltas", Some(json!({})));
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn sync_deltas_authenticated_returns_success() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    // DeltaRequest requires device_id and last_sync_at.
    let req = authed_req(
        "POST",
        "/api/v1/sync/deltas",
        &teacher.token,
        Some(json!({
            "device_id": "test-device-001",
            "last_sync_at": "2024-01-01T00:00:00Z"
        })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(
        resp.status().is_success(),
        "expected 2xx, got {}",
        resp.status()
    );
}

#[tokio::test]
async fn sync_deltas_with_since_timestamp_returns_structured_payload() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        "/api/v1/sync/deltas",
        &teacher.token,
        Some(json!({
            "device_id": "test-device-001",
            "last_sync_at": "2025-01-01T00:00:00Z"
        })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);

    let body = body_json(resp).await;
    assert!(body.is_object() || body["data"].is_object(), "body: {body}");
}
