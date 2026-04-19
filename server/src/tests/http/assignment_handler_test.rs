use axum::http::StatusCode;
use serde_json::json;
use tower::ServiceExt;
use uuid::Uuid;

use crate::tests::common::{
    seeds::{seed_class, seed_class_with_student, seed_student, seed_teacher},
    test_app::build_test_app,
    test_db::test_db,
};
use crate::tests::http::{authed_req, body_json, json_req};

fn create_assignment_body(_class_id: Uuid) -> serde_json::Value {
    // Server requires YYYY-MM-DDTHH:MM:SS format (no timezone suffix).
    json!({
        "title": "Homework 1",
        "instructions": "Complete exercises 1-5",
        "total_points": 100,
        "allows_text_submission": true,
        "allows_file_submission": false,
        "due_at": "2030-12-31T23:59:59"
    })
}

/// Creates an assignment via API and returns its ID.
async fn create_assignment(
    db: &sea_orm::DatabaseConnection,
    class_id: Uuid,
    token: &str,
) -> Uuid {
    let app = crate::tests::common::test_app::build_test_app(db.clone()).await;
    let req = authed_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/assignments"),
        token,
        Some(create_assignment_body(class_id)),
    );
    let resp = app.oneshot(req).await.unwrap();
    let body = body_json(resp).await;
    let id_str = body["data"]["id"]
        .as_str()
        .unwrap_or_else(|| panic!("create_assignment: no id in {body}"));
    id_str.parse().expect("create_assignment: id not a UUID")
}

// ── create assignment ─────────────────────────────────────────────────────────

#[tokio::test]
async fn create_assignment_success() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/assignments"),
        &teacher.token,
        Some(create_assignment_body(class_id)),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_success(), "got {}", resp.status());
}

#[tokio::test]
async fn create_assignment_unauthenticated_returns_401() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/assignments"),
        Some(create_assignment_body(class_id)),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn create_assignment_missing_required_fields_returns_error() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/assignments"),
        &teacher.token,
        Some(json!({ "title": "No other fields" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error());
}

// ── list assignments ──────────────────────────────────────────────────────────

#[tokio::test]
async fn list_assignments_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/assignments"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn list_assignments_unauthenticated_returns_401() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = json_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/assignments"),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── get assignment ────────────────────────────────────────────────────────────

#[tokio::test]
async fn get_assignment_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let assignment_id = create_assignment(&db, class_id, &teacher.token).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/assignments/{assignment_id}"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn get_assignment_nonexistent_returns_404() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/assignments/{}", Uuid::new_v4()),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

// ── update assignment ─────────────────────────────────────────────────────────

#[tokio::test]
async fn update_assignment_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let assignment_id = create_assignment(&db, class_id, &teacher.token).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "PUT",
        &format!("/api/v1/assignments/{assignment_id}"),
        &teacher.token,
        Some(json!({ "title": "Updated Homework" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn update_nonexistent_assignment_returns_404() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "PUT",
        &format!("/api/v1/assignments/{}", Uuid::new_v4()),
        &teacher.token,
        Some(json!({ "title": "Ghost" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

// ── delete assignment ─────────────────────────────────────────────────────────

#[tokio::test]
async fn delete_assignment_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let assignment_id = create_assignment(&db, class_id, &teacher.token).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "DELETE",
        &format!("/api/v1/assignments/{assignment_id}"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

// ── publish / unpublish ───────────────────────────────────────────────────────

#[tokio::test]
async fn publish_assignment_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let assignment_id = create_assignment(&db, class_id, &teacher.token).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        &format!("/api/v1/assignments/{assignment_id}/publish"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn unpublish_assignment_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let assignment_id = create_assignment(&db, class_id, &teacher.token).await;

    // unpublish requires the assignment to already be published.
    let publish_app = build_test_app(db.clone()).await;
    publish_app
        .oneshot(authed_req(
            "POST",
            &format!("/api/v1/assignments/{assignment_id}/publish"),
            &teacher.token,
            None,
        ))
        .await
        .unwrap();

    let app = build_test_app(db).await;
    let req = authed_req(
        "POST",
        &format!("/api/v1/assignments/{assignment_id}/unpublish"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_success(), "got {}", resp.status());
}

// ── student: list assignments ─────────────────────────────────────────────────

#[tokio::test]
async fn student_list_assignments_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let student = seed_student(&db).await;
    let class_id = seed_class_with_student(&db, teacher.id, student.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/student-assignments"),
        &student.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

// ── list submissions (teacher) ────────────────────────────────────────────────

#[tokio::test]
async fn list_submissions_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "GET",
        &format!("/api/v1/assignments/{}/submissions", Uuid::new_v4()),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn list_submissions_nonexistent_assignment_returns_error() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/assignments/{}/submissions", Uuid::new_v4()),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error());
}
