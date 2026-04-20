use axum::http::StatusCode;
use tower::ServiceExt;
use uuid::Uuid;

use crate::tests::common::{
    seeds::{seed_class_with_student, seed_student, seed_teacher},
    test_app::build_test_app,
    test_db::test_db,
};
use crate::tests::http::{authed_req, json_req};

// ── get_student_tasks ────────────────────────────────────────────────────────

#[tokio::test]
async fn get_tasks_as_student_in_class_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let student = seed_student(&db).await;
    let class_id = seed_class_with_student(&db, teacher.id, student.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/tasks"),
        &student.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn get_tasks_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "GET",
        &format!("/api/v1/classes/{}/tasks", Uuid::new_v4()),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn get_tasks_as_teacher_returns_403() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = crate::tests::common::seeds::seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/tasks"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::FORBIDDEN);
}

#[tokio::test]
async fn get_tasks_nonexistent_class_returns_200_empty() {
    // Handler queries assignments + assessments; both return empty for unknown class_id.
    let db = test_db().await;
    let student = seed_student(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/classes/{}/tasks", Uuid::new_v4()),
        &student.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}
