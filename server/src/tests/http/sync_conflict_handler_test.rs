use axum::http::StatusCode;
use serde_json::json;
use tower::ServiceExt;

use crate::tests::common::{
    seeds::seed_teacher,
    test_app::build_test_app,
    test_db::test_db,
};
use crate::tests::http::{authed_req, json_req};

// ── resolve_conflict ──────────────────────────────────────────────────────────

#[tokio::test]
async fn resolve_conflict_server_wins_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        "/api/v1/sync/conflicts/resolve",
        &teacher.token,
        Some(json!({
            "conflict_id": "conflict-abc-123",
            "resolution": "server_wins"
        })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn resolve_conflict_client_wins_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        "/api/v1/sync/conflicts/resolve",
        &teacher.token,
        Some(json!({
            "conflict_id": "conflict-abc-456",
            "resolution": "client_wins"
        })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn resolve_conflict_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        "/api/v1/sync/conflicts/resolve",
        Some(json!({
            "conflict_id": "conflict-abc-123",
            "resolution": "server_wins"
        })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn resolve_conflict_missing_field_returns_422() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    // Missing conflict_id
    let req = authed_req(
        "POST",
        "/api/v1/sync/conflicts/resolve",
        &teacher.token,
        Some(json!({ "resolution": "server_wins" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error(), "got {}", resp.status());
}

#[tokio::test]
async fn resolve_conflict_unknown_strategy_returns_error() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        "/api/v1/sync/conflicts/resolve",
        &teacher.token,
        Some(json!({
            "conflict_id": "conflict-xyz",
            "resolution": "unknown_strategy"
        })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error(), "got {}", resp.status());
}
