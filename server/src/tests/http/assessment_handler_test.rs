use axum::http::StatusCode;
use serde_json::json;
use tower::ServiceExt;
use uuid::Uuid;

use crate::tests::common::{
    seeds::{seed_class, seed_student, seed_teacher},
    test_app::build_test_app,
    test_db::test_db,
};
use crate::tests::http::{authed_req, body_json, json_req};

fn create_assessment_body() -> serde_json::Value {
    // Required: title, time_limit_minutes, open_at, close_at (YYYY-MM-DDTHH:MM:SS format).
    json!({
        "title": "Quiz 1",
        "description": "First quiz",
        "time_limit_minutes": 30,
        "open_at": "2024-01-01T00:00:00",
        "close_at": "2030-12-31T23:59:59"
    })
}

/// Creates an assessment via API and returns its ID.
async fn create_assessment(
    db: &sea_orm::DatabaseConnection,
    class_id: Uuid,
    token: &str,
) -> Uuid {
    let app = crate::tests::common::test_app::build_test_app(db.clone()).await;
    let req = authed_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/assessments"),
        token,
        Some(create_assessment_body()),
    );
    let resp = app.oneshot(req).await.unwrap();
    let body = body_json(resp).await;
    let id_str = body["data"]["id"]
        .as_str()
        .unwrap_or_else(|| panic!("create_assessment: no id in {body}"));
    id_str.parse().expect("create_assessment: id not a UUID")
}

// ── create assessment ─────────────────────────────────────────────────────────

#[tokio::test]
async fn create_assessment_success() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/assessments"),
        &teacher.token,
        Some(create_assessment_body()),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_success(), "got {}", resp.status());
}

#[tokio::test]
async fn create_assessment_unauthenticated_returns_401() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/assessments"),
        Some(create_assessment_body()),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn create_assessment_missing_title_returns_error() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/assessments"),
        &teacher.token,
        Some(json!({ "description": "no title" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error());
}

// ── list assessments ──────────────────────────────────────────────────────────

#[tokio::test]
async fn list_assessments_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/assessments"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

// ── get assessment ────────────────────────────────────────────────────────────

#[tokio::test]
async fn get_assessment_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let assessment_id = create_assessment(&db, class_id, &teacher.token).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/assessments/{assessment_id}"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn get_assessment_nonexistent_returns_404() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/assessments/{}", Uuid::new_v4()),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

// ── update assessment ─────────────────────────────────────────────────────────

#[tokio::test]
async fn update_assessment_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let assessment_id = create_assessment(&db, class_id, &teacher.token).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "PUT",
        &format!("/api/v1/assessments/{assessment_id}"),
        &teacher.token,
        Some(json!({ "title": "Quiz 1 Updated" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

// ── delete assessment ─────────────────────────────────────────────────────────

#[tokio::test]
async fn delete_assessment_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let assessment_id = create_assessment(&db, class_id, &teacher.token).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "DELETE",
        &format!("/api/v1/assessments/{assessment_id}"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

// ── publish / unpublish ───────────────────────────────────────────────────────

#[tokio::test]
async fn publish_assessment_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let assessment_id = create_assessment(&db, class_id, &teacher.token).await;

    // publish_assessment requires at least one question.
    let add_q_app = build_test_app(db.clone()).await;
    let q_req = authed_req(
        "POST",
        &format!("/api/v1/assessments/{assessment_id}/questions"),
        &teacher.token,
        // Endpoint uses AddQuestionsRequest which wraps questions in an array.
        Some(json!({
            "questions": [{
                "question_type": "multiple_choice",
                "question_text": "What is 2+2?",
                "points": 5,
                "order_index": 1,
                "choices": [
                    { "choice_text": "3", "is_correct": false, "order_index": 1 },
                    { "choice_text": "4", "is_correct": true,  "order_index": 2 }
                ]
            }]
        })),
    );
    add_q_app.oneshot(q_req).await.unwrap();

    let app = build_test_app(db).await;
    let req = authed_req(
        "POST",
        &format!("/api/v1/assessments/{assessment_id}/publish"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn publish_assessment_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        &format!("/api/v1/assessments/{}/publish", Uuid::new_v4()),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── questions ─────────────────────────────────────────────────────────────────

#[tokio::test]
async fn add_question_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let assessment_id = create_assessment(&db, class_id, &teacher.token).await;
    let app = build_test_app(db).await;

    // AddQuestionRequest requires: question_type, question_text, points, order_index.
    // ChoiceInput requires: choice_text, is_correct, order_index.
    let req = authed_req(
        "POST",
        &format!("/api/v1/assessments/{assessment_id}/questions"),
        &teacher.token,
        // Endpoint uses AddQuestionsRequest which wraps questions in an array.
        Some(json!({
            "questions": [{
                "question_type": "multiple_choice",
                "question_text": "What is 2+2?",
                "points": 5,
                "order_index": 1,
                "choices": [
                    { "choice_text": "3", "is_correct": false, "order_index": 1 },
                    { "choice_text": "4", "is_correct": true,  "order_index": 2 }
                ]
            }]
        })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_success(), "got {}", resp.status());
}

#[tokio::test]
async fn add_question_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        &format!("/api/v1/assessments/{}/questions", Uuid::new_v4()),
        Some(json!({ "question_text": "Q?" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── student: start assessment ─────────────────────────────────────────────────

#[tokio::test]
async fn student_start_assessment_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        &format!("/api/v1/assessments/{}/start", Uuid::new_v4()),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn student_start_nonexistent_assessment_returns_error() {
    let db = test_db().await;
    let student = seed_student(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        &format!("/api/v1/assessments/{}/start", Uuid::new_v4()),
        &student.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error());
}

// ── get assessment submissions ────────────────────────────────────────────────

#[tokio::test]
async fn list_assessment_submissions_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "GET",
        &format!("/api/v1/assessments/{}/submissions", Uuid::new_v4()),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── statistics ────────────────────────────────────────────────────────────────

#[tokio::test]
async fn get_statistics_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "GET",
        &format!("/api/v1/assessments/{}/statistics", Uuid::new_v4()),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}
