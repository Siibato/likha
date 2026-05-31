//! Unit tests for GradeComputationService pure logic:
//! - `From` conversions for response schemas
//! - `effective_score` override logic (override_score takes precedence over score)
//! - `PeriodGradeResponse` descriptor lookup via `From`
//!
//! Note: Mock-based tests for GradeComputationService CRUD require
//! `mockall = "0.13"` to be vendored. Those tests are pending.

use uuid::Uuid;
use crate::schema::grading_schema::{
    GradingConfigResponse, GradeItemResponse, GradeScoreResponse, PeriodGradeResponse,
};

fn make_grade_record(
    ww: f64,
    pt: f64,
    qa: f64,
    period: Option<i32>,
) -> ::entity::grade_record::Model {
    let now = chrono::Utc::now().naive_utc();
    ::entity::grade_record::Model {
        id: Uuid::new_v4(),
        class_id: Uuid::new_v4(),
        grading_period_number: period,
        ww_weight: ww,
        pt_weight: pt,
        qa_weight: qa,
        created_at: now,
        updated_at: now,
        deleted_at: None,
    }
}

fn make_grade_item() -> ::entity::grade_items::Model {
    let now = chrono::Utc::now().naive_utc();
    ::entity::grade_items::Model {
        id: Uuid::new_v4(),
        class_id: Uuid::new_v4(),
        title: "Long Quiz 1".to_string(),
        component: "written_work".to_string(),
        grading_period_number: Some(1),
        total_points: 50.0,
        source_type: "manual".to_string(),
        source_id: None,
        order_index: 0,
        created_at: now,
        updated_at: now,
        deleted_at: None,
    }
}

fn make_grade_score(
    score: Option<f64>,
    override_score: Option<f64>,
) -> ::entity::grade_scores::Model {
    let now = chrono::Utc::now().naive_utc();
    ::entity::grade_scores::Model {
        id: Uuid::new_v4(),
        grade_item_id: Uuid::new_v4(),
        student_id: Uuid::new_v4(),
        score,
        is_auto_populated: false,
        override_score,
        created_at: now,
        updated_at: now,
        deleted_at: None,
    }
}

fn make_period_grade(
    initial_grade: Option<f64>,
    transmuted_grade: Option<i32>,
) -> ::entity::period_grades::Model {
    let now = chrono::Utc::now().naive_utc();
    ::entity::period_grades::Model {
        id: Uuid::new_v4(),
        class_id: Uuid::new_v4(),
        student_id: Uuid::new_v4(),
        grading_period_number: 1,
        initial_grade,
        transmuted_grade,
        is_locked: false,
        computed_at: None,
        created_at: now,
        updated_at: now,
        deleted_at: None,
    }
}

// ── GradingConfigResponse::from ──────────────────────────────────────────────

#[test]
fn test_grading_config_response_from_grade_record_maps_weights() {
    let model = make_grade_record(30.0, 50.0, 20.0, Some(1));
    let response = GradingConfigResponse::from(model.clone());
    assert_eq!(response.id, model.id.to_string());
    assert_eq!(response.ww_weight, 30.0);
    assert_eq!(response.pt_weight, 50.0);
    assert_eq!(response.qa_weight, 20.0);
    assert_eq!(response.grading_period_number, Some(1));
}

#[test]
fn test_grading_config_response_null_period_maps_to_none() {
    let model = make_grade_record(40.0, 40.0, 20.0, None);
    let response = GradingConfigResponse::from(model);
    assert!(response.grading_period_number.is_none());
}

// ── GradeItemResponse::from ──────────────────────────────────────────────────

#[test]
fn test_grade_item_response_from_model_maps_fields() {
    let model = make_grade_item();
    let response = GradeItemResponse::from(model.clone());
    assert_eq!(response.id, model.id.to_string());
    assert_eq!(response.title, "Long Quiz 1");
    assert_eq!(response.component, "written_work");
    assert_eq!(response.total_points, 50.0);
    assert_eq!(response.order_index, 0);
    assert!(response.source_id.is_none());
}

// ── GradeScoreResponse::from — effective_score logic ────────────────────────

#[test]
fn test_grade_score_effective_score_uses_override_when_present() {
    let model = make_grade_score(Some(40.0), Some(45.0));
    let response = GradeScoreResponse::from(model);
    assert_eq!(response.score, Some(40.0));
    assert_eq!(response.override_score, Some(45.0));
    assert_eq!(response.effective_score, Some(45.0));
}

#[test]
fn test_grade_score_effective_score_falls_back_to_score_when_no_override() {
    let model = make_grade_score(Some(38.0), None);
    let response = GradeScoreResponse::from(model);
    assert_eq!(response.effective_score, Some(38.0));
    assert!(response.override_score.is_none());
}

#[test]
fn test_grade_score_effective_score_is_none_when_both_absent() {
    let model = make_grade_score(None, None);
    let response = GradeScoreResponse::from(model);
    assert!(response.effective_score.is_none());
}

// ── PeriodGradeResponse::from — descriptor lookup ───────────────────────────

#[test]
fn test_period_grade_descriptor_outstanding_for_transmuted_90() {
    let model = make_period_grade(Some(80.0), Some(90));
    let response = PeriodGradeResponse::from(model);
    assert_eq!(response.descriptor.as_deref(), Some("Outstanding"));
}

#[test]
fn test_period_grade_descriptor_did_not_meet_for_transmuted_74() {
    let model = make_period_grade(Some(55.0), Some(74));
    let response = PeriodGradeResponse::from(model);
    assert_eq!(response.descriptor.as_deref(), Some("Did Not Meet Expectations"));
}

#[test]
fn test_period_grade_descriptor_none_when_no_transmuted_grade() {
    let model = make_period_grade(None, None);
    let response = PeriodGradeResponse::from(model);
    assert!(response.descriptor.is_none());
}

#[test]
fn test_period_grade_descriptor_very_satisfactory_for_87() {
    let model = make_period_grade(Some(75.0), Some(87));
    let response = PeriodGradeResponse::from(model);
    assert_eq!(response.descriptor.as_deref(), Some("Very Satisfactory"));
}

#[test]
fn test_period_grade_descriptor_fairly_satisfactory_for_75() {
    let model = make_period_grade(Some(60.0), Some(75));
    let response = PeriodGradeResponse::from(model);
    assert_eq!(response.descriptor.as_deref(), Some("Fairly Satisfactory"));
}

#[test]
fn test_period_grade_response_is_locked_maps_correctly() {
    let mut model = make_period_grade(Some(70.0), Some(80));
    model.is_locked = true;
    let response = PeriodGradeResponse::from(model);
    assert!(response.is_locked);
}
