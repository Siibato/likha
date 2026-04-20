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

/// Creates a material via the HTTP API and returns its UUID.
async fn seed_material(
    db: &sea_orm::DatabaseConnection,
    teacher_token: &str,
    class_id: Uuid,
) -> Uuid {
    let app = build_test_app(db.clone()).await;
    let req = authed_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/materials"),
        teacher_token,
        Some(json!({ "title": "Lesson 1 Notes" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    let body = body_json(resp).await;
    body["data"]["id"]
        .as_str()
        .unwrap_or_else(|| panic!("seed_material: missing id in {body}"))
        .parse()
        .expect("seed_material: id not a UUID")
}

// ── create material ───────────────────────────────────────────────────────────

#[tokio::test]
async fn create_material_as_teacher_returns_201() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/materials"),
        &teacher.token,
        Some(json!({ "title": "Chapter 1" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::CREATED);
}

#[tokio::test]
async fn create_material_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        &format!("/api/v1/classes/{}/materials", Uuid::new_v4()),
        Some(json!({ "title": "Chapter 1" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn create_material_missing_title_returns_error() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/materials"),
        &teacher.token,
        Some(json!({})),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert!(resp.status().is_client_error(), "got {}", resp.status());
}

#[tokio::test]
async fn create_material_as_student_returns_403() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let student = seed_student(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/materials"),
        &student.token,
        Some(json!({ "title": "Chapter 1" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::FORBIDDEN);
}

// ── list materials ────────────────────────────────────────────────────────────

#[tokio::test]
async fn list_materials_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/classes/{class_id}/materials"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn list_materials_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "GET",
        &format!("/api/v1/classes/{}/materials", Uuid::new_v4()),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── get material detail ───────────────────────────────────────────────────────

#[tokio::test]
async fn get_material_detail_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let material_id = seed_material(&db, &teacher.token, class_id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/materials/{material_id}"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn get_material_detail_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("GET", &format!("/api/v1/materials/{}", Uuid::new_v4()), None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn get_material_detail_nonexistent_returns_404() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/materials/{}", Uuid::new_v4()),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

// ── update material ───────────────────────────────────────────────────────────

#[tokio::test]
async fn update_material_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let material_id = seed_material(&db, &teacher.token, class_id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "PUT",
        &format!("/api/v1/materials/{material_id}"),
        &teacher.token,
        Some(json!({ "title": "Updated Lesson" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn update_material_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "PUT",
        &format!("/api/v1/materials/{}", Uuid::new_v4()),
        Some(json!({ "title": "Updated" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn update_material_nonexistent_returns_404() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "PUT",
        &format!("/api/v1/materials/{}", Uuid::new_v4()),
        &teacher.token,
        Some(json!({ "title": "Updated" })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

// ── delete material ───────────────────────────────────────────────────────────

#[tokio::test]
async fn delete_material_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let material_id = seed_material(&db, &teacher.token, class_id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "DELETE",
        &format!("/api/v1/materials/{material_id}"),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn delete_material_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("DELETE", &format!("/api/v1/materials/{}", Uuid::new_v4()), None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn delete_material_nonexistent_returns_404() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "DELETE",
        &format!("/api/v1/materials/{}", Uuid::new_v4()),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

// ── materials metadata ────────────────────────────────────────────────────────

#[tokio::test]
async fn get_materials_metadata_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req("GET", "/api/v1/materials/metadata", &teacher.token, None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn get_materials_metadata_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req("GET", "/api/v1/materials/metadata", None);
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── reorder single material ───────────────────────────────────────────────────

#[tokio::test]
async fn reorder_material_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let material_id = seed_material(&db, &teacher.token, class_id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        &format!("/api/v1/materials/{material_id}/reorder"),
        &teacher.token,
        Some(json!({ "new_order_index": 0 })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn reorder_material_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        &format!("/api/v1/materials/{}/reorder", Uuid::new_v4()),
        Some(json!({ "new_order_index": 0 })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── bulk reorder materials ────────────────────────────────────────────────────

#[tokio::test]
async fn reorder_materials_returns_200() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let class_id = seed_class(&db, teacher.id).await;
    let material_id = seed_material(&db, &teacher.token, class_id).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "POST",
        &format!("/api/v1/classes/{class_id}/materials/reorder"),
        &teacher.token,
        Some(json!({ "material_ids": [material_id] })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[tokio::test]
async fn reorder_materials_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "POST",
        &format!("/api/v1/classes/{}/materials/reorder", Uuid::new_v4()),
        Some(json!({ "material_ids": [] })),
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── delete material file ──────────────────────────────────────────────────────

#[tokio::test]
async fn delete_material_file_nonexistent_returns_404() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "DELETE",
        &format!("/api/v1/material-files/{}", Uuid::new_v4()),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

#[tokio::test]
async fn delete_material_file_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "DELETE",
        &format!("/api/v1/material-files/{}", Uuid::new_v4()),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// ── download material file ────────────────────────────────────────────────────

#[tokio::test]
async fn download_material_file_nonexistent_returns_404() {
    let db = test_db().await;
    let teacher = seed_teacher(&db).await;
    let app = build_test_app(db).await;

    let req = authed_req(
        "GET",
        &format!("/api/v1/material-files/{}/download", Uuid::new_v4()),
        &teacher.token,
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

#[tokio::test]
async fn download_material_file_unauthenticated_returns_401() {
    let db = test_db().await;
    let app = build_test_app(db).await;

    let req = json_req(
        "GET",
        &format!("/api/v1/material-files/{}/download", Uuid::new_v4()),
        None,
    );
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// Note: POST /materials/{id}/files (multipart upload) is skipped — multipart
// body construction in in-process tests is excessively complex for the value gained.
