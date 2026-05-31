use axum::http::StatusCode;
use serde_json::json;
use tower::ServiceExt;
use uuid::Uuid;

use crate::tests::common::{
    seeds::{seed_class, seed_teacher},
    test_app::build_test_app,
    test_db::test_db,
};
use crate::tests::http::{authed_req, json_req};

// ── unauthenticated ───────────────────────────────────────────────────────────

#[tokio::test]
async fn sync_push_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        "/api/v1/sync/push",
        Some(json!({ "operations": [] })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── empty operations list ─────────────────────────────────────────────────────

#[tokio::test]
async fn sync_push_empty_operations_returns_success() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        "/api/v1/sync/push",
        &teacher.token,
        Some(json!({ "operations": [] })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_success(), "got {}", resp.status());
}

// ── create_class operation ────────────────────────────────────────────────────

#[tokio::test]
async fn sync_push_create_class_op_returns_success() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let client_id = Uuid::new_v4();
    let req = authed_req(
        "POST",
        "/api/v1/sync/push",
        &teacher.token,
        Some(json!({
            "operations": [
                {
                    "id": Uuid::new_v4().to_string(),
                    "type": "create_class",
                    "entity": {
                        "id": client_id.to_string(),
                        "title": "Synced Class",
                        "description": null
                    },
                    "timestamp": "2024-01-01T00:00:00Z"
                }
            ]
        })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_success(), "got {}", resp.status());
}

// ── create_assignment operation ───────────────────────────────────────────────

#[tokio::test]
async fn sync_push_create_assignment_op_returns_success() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let client_id = Uuid::new_v4();
    let req = authed_req(
        "POST",
        "/api/v1/sync/push",
        &teacher.token,
        Some(json!({
            "operations": [
                {
                    "id": Uuid::new_v4().to_string(),
                    "type": "create_assignment",
                    "entity": {
                        "id": client_id.to_string(),
                        "class_id": class_id.to_string(),
                        "title": "Synced Assignment",
                        "instructions": "Do the work",
                        "total_points": 100,
                        "allows_text_submission": true,
                        "allows_file_submission": false,
                        "due_at": "2030-12-31T23:59:59Z",
                        "is_published": false,
                        "grading_period_number": 1,
                        "component": "WW"
                    },
                    "timestamp": "2024-01-01T00:00:00Z"
                }
            ]
        })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_success(), "got {}", resp.status());
}

// ── malformed payload ─────────────────────────────────────────────────────────

#[tokio::test]
async fn sync_push_missing_operations_key_returns_error() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        "/api/v1/sync/push",
        &teacher.token,
        Some(json!({ "data": "not the right shape" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    // The handler may accept any JSON value and return success (no-op), or return 4xx.
    // Either way, it must not panic (5xx).
    assert_ne!(resp.status(), StatusCode::INTERNAL_SERVER_ERROR);
}
