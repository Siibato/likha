use axum::http::StatusCode;
use serde_json::json;
use tower::ServiceExt;
use uuid::Uuid;

use crate::tests::common::{
    seeds::{seed_class, seed_teacher},
    test_app::build_test_app,
    test_db::test_db,
};
use crate::tests::http::{authed_req, body_json, json_req};

fn create_tos_body() -> serde_json::Value {
    json!({
        "title": "TOS Quarter 1",
        "grading_period_number": 1,
        "classification_mode": "difficulty",
        "total_items": 40,
        "easy_percentage": 30.0,
        "medium_percentage": 50.0,
        "hard_percentage": 20.0
    })
}

/// Creates a TOS via API and returns its ID.
async fn create_tos(db: &sea_orm::DatabaseConnection, class_id: Uuid, token: &str) -> Uuid {
    let app = crate::tests::common::test_app::build_test_app(db.clone()).await;
    let req = authed_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/tos"),
        token,
        Some(create_tos_body()),
    );
    let resp = app.oneshot(req).await.unwrap();
    let body = body_json(resp).await;
    let id_str = body["data"]["id"]
        .as_str()
        .unwrap_or_else(|| panic!("create_tos: no id in {body}"));
    id_str.parse().expect("create_tos: id not a UUID")
}

// ── list TOS ──────────────────────────────────────────────────────────────────

#[tokio::test]
async fn list_tos_returns_200_empty() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/tos"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn list_tos_unauthenticated_returns_401() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = json_req("GET", &format!("/api/v1/classes/{class_id}/tos"), None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── create TOS ────────────────────────────────────────────────────────────────

#[tokio::test]
async fn create_tos_success() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/tos"),
        &teacher.token,
        Some(create_tos_body()),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_success(), "got {}", resp.status());
}

#[tokio::test]
async fn create_tos_unauthenticated_returns_401() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/tos"),
        Some(create_tos_body()),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn create_tos_missing_required_fields_returns_error() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/tos"),
        &teacher.token,
        Some(json!({ "title": "Only title" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error());
}

// ── get TOS ───────────────────────────────────────────────────────────────────

#[tokio::test]
async fn get_tos_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let tos_id = create_tos(&db, class_id, &teacher.token).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/tos/{tos_id}"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn get_tos_nonexistent_returns_404() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/tos/{}", Uuid::new_v4()),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

// ── update TOS ────────────────────────────────────────────────────────────────

#[tokio::test]
async fn update_tos_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let tos_id = create_tos(&db, class_id, &teacher.token).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "PUT",
        &format!("/api/v1/tos/{tos_id}"),
        &teacher.token,
        Some(json!({ "title": "TOS Updated" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn update_nonexistent_tos_returns_404() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "PUT",
        &format!("/api/v1/tos/{}", Uuid::new_v4()),
        &teacher.token,
        Some(json!({ "title": "Ghost TOS" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

// ── delete TOS ────────────────────────────────────────────────────────────────

#[tokio::test]
async fn delete_tos_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let tos_id = create_tos(&db, class_id, &teacher.token).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "DELETE",
        &format!("/api/v1/tos/{tos_id}"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn delete_nonexistent_tos_returns_404() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "DELETE",
        &format!("/api/v1/tos/{}", Uuid::new_v4()),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

// ── competencies ──────────────────────────────────────────────────────────────

#[tokio::test]
async fn add_competency_returns_success() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let tos_id = create_tos(&db, class_id, &teacher.token).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        &format!("/api/v1/tos/{tos_id}/competencies"),
        &teacher.token,
        Some(json!({
            "competency_text": "Identify key concepts",
            "time_units_taught": 3
        })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_success(), "got {}", resp.status());
}

#[tokio::test]
async fn add_competency_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        &format!("/api/v1/tos/{}/competencies", Uuid::new_v4()),
        Some(json!({ "competency_text": "x", "time_units_taught": 1 })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── search MELCS ─────────────────────────────────────────────────────────────

#[tokio::test]
async fn search_melcs_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req("GET", "/api/v1/melcs?q=math", &teacher.token, None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}
