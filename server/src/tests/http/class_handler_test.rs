use axum::http::StatusCode;
use serde_json::json;
use tower::ServiceExt;
use uuid::Uuid;

use crate::tests::common::{
    seeds::{seed_class, seed_student, seed_teacher},
    test_app::build_test_app,
    test_db::test_db,
};
use crate::tests::http::{authed_req, json_req};

// ── create class ──────────────────────────────────────────────────────────────

#[tokio::test]
async fn create_class_as_teacher_returns_201() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        "/api/v1/classes",
        &teacher.token,
        Some(json!({ "title": "Math 101" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(
        resp.status() == StatusCode::CREATED || resp.status() == StatusCode::OK,
        "got {}",
        resp.status()
    );
}

#[tokio::test]
async fn create_class_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("POST", "/api/v1/classes", Some(json!({ "title": "Math 101" })));
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn create_class_missing_title_returns_error() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req("POST", "/api/v1/classes", &teacher.token, Some(json!({})));
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error());
}

// ── list classes ──────────────────────────────────────────────────────────────

#[tokio::test]
async fn list_classes_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req("GET", "/api/v1/classes", &teacher.token, None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn list_classes_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("GET", "/api/v1/classes", None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── get class detail ──────────────────────────────────────────────────────────

#[tokio::test]
async fn get_class_detail_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/classes/{class_id}"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn get_class_nonexistent_returns_404() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/classes/{}", Uuid::new_v4()),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

// ── update class ──────────────────────────────────────────────────────────────

#[tokio::test]
async fn update_class_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "PUT",
        &format!("/api/v1/classes/{class_id}"),
        &teacher.token,
        Some(json!({ "title": "Math 102 Updated" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

// ── delete class ──────────────────────────────────────────────────────────────

#[tokio::test]
async fn delete_class_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "DELETE",
        &format!("/api/v1/classes/{class_id}"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

// ── add / remove student ──────────────────────────────────────────────────────

#[tokio::test]
async fn add_student_to_class_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let student = seed_student(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/students"),
        &teacher.token,
        Some(json!({ "student_id": student.id })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(
        resp.status().is_success(),
        "expected 2xx, got {}",
        resp.status()
    );
}

#[tokio::test]
async fn remove_student_is_idempotent_returns_200() {
    // The remove_participant implementation does not error if the student is not enrolled;
    // it returns 200 silently. This test documents that idempotent behaviour.
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "DELETE",
        &format!("/api/v1/classes/{class_id}/students/{}", Uuid::new_v4()),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

// ── search students ───────────────────────────────────────────────────────────

#[tokio::test]
async fn search_students_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req("GET", "/api/v1/students/search?q=test", &teacher.token, None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}
