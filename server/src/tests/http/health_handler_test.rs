use axum::{body::Body, http::{Request, StatusCode}};
use tower::ServiceExt;

use crate::tests::common::{test_app::build_test_app, test_db::test_db};

#[tokio::test]
async fn test_health_check_returns_200() {
    let db = test_db().await;
    let app = build_test_app(db).await;
    let req = Request::builder()
        .uri("/api/v1/health")
        .body(Body::empty())
        .unwrap();
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn test_readiness_check_returns_200() {
    let db = test_db().await;
    let app = build_test_app(db).await;
    let req = Request::builder()
        .uri("/api/v1/health/ready")
        .body(Body::empty())
        .unwrap();
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn test_database_id_returns_200() {
    let db = test_db().await;
    let app = build_test_app(db).await;
    let req = Request::builder()
        .uri("/api/v1/database-id")
        .body(Body::empty())
        .unwrap();
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}
