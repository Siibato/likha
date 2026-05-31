use axum::http::StatusCode;
use serde_json::json;
use tower::ServiceExt;

use crate::tests::common::{
    seeds::{seed_class, seed_class_with_student, seed_student, seed_teacher},
    test_app::build_test_app,
    test_db::test_db,
};
use crate::tests::http::{authed_req, json_req};

fn grading_config_body() -> serde_json::Value {
    // subject_group must be a DepEd preset key (see deped_weights.rs).
    json!({
        "grade_level": "Grade 7",
        "subject_group": "math_sci",
        "school_year": "2024-2025"
    })
}

// ── grading config ────────────────────────────────────────────────────────────

#[tokio::test]
async fn get_grading_config_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/grading-config"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(
        resp.status().is_success() || resp.status() == StatusCode::NOT_FOUND,
        "got {}",
        resp.status()
    );
}

#[tokio::test]
async fn get_grading_config_unauthenticated_returns_401() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = json_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/grading-config"),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn setup_grading_config_returns_success() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/grading-config/setup"),
        &teacher.token,
        Some(grading_config_body()),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_success(), "got {}", resp.status());
}

#[tokio::test]
async fn setup_grading_config_unauthenticated_returns_401() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/grading-config/setup"),
        Some(grading_config_body()),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── grade items ───────────────────────────────────────────────────────────────

#[tokio::test]
async fn list_grade_items_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/grade-items"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(
        resp.status().is_success() || resp.status() == StatusCode::NOT_FOUND,
        "got {}",
        resp.status()
    );
}

#[tokio::test]
async fn list_grade_items_unauthenticated_returns_401() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = json_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/grade-items"),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── computed grades ───────────────────────────────────────────────────────────

#[tokio::test]
async fn get_grades_unauthenticated_returns_401() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = json_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/grades"),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn get_grades_authenticated_returns_200_or_404() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/grades"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(
        resp.status().is_success() || resp.status() == StatusCode::NOT_FOUND,
        "got {}",
        resp.status()
    );
}

#[tokio::test]
async fn compute_grades_unauthenticated_returns_401() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/grades/compute"),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── DepEd presets ─────────────────────────────────────────────────────────────

#[tokio::test]
async fn get_deped_presets_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req("GET", "/api/v1/grading/deped-presets", &teacher.token, None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn get_deped_presets_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("GET", "/api/v1/grading/deped-presets", None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── student: my grades ────────────────────────────────────────────────────────

#[tokio::test]
async fn student_get_my_grades_unauthenticated_returns_401() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = json_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/my-grades"),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn student_get_my_grades_authenticated_returns_200_or_404() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let student = seed_student(&db).await;
    let class_id = seed_class_with_student(&db, teacher.id, student.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/my-grades"),
        &student.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(
        resp.status().is_success() || resp.status() == StatusCode::NOT_FOUND,
        "got {}",
        resp.status()
    );
}

// ── SF9 / SF10 ────────────────────────────────────────────────────────────────

#[tokio::test]
async fn get_sf9_unauthenticated_returns_401() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let student = seed_student(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = json_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/sf9/{}", student.id),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn get_general_averages_unauthenticated_returns_401() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = json_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/grades/general-average"),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}
