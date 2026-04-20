//! Unit tests for TOS service pure logic.
//!
//! Tests cover schema serialization, `From` conversion helpers,
//! and pure data-mapping paths that don't require a database.
//!
//! Note: Mock-based tests for TosService CRUD operations require
//! `mockall = "0.13"` to be vendored. Those tests are pending.

use crate::schema::tos_schema::{
    CreateTosRequest, CreateCompetencyRequest, BulkAddCompetenciesRequest,
    MelcSearchResponse, MelcEntry,
};

#[test]
fn test_create_tos_request_deserializes_from_json() {
    let json = serde_json::json!({
        "title": "Q1 TOS",
        "grading_period_number": 1,
        "classification_mode": "blooms",
        "total_items": 30
    });

    let req: CreateTosRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.title, "Q1 TOS");
    assert_eq!(req.grading_period_number, 1);
    assert_eq!(req.classification_mode, "blooms");
}

#[test]
fn test_create_tos_request_with_total_items() {
    let json = serde_json::json!({
        "title": "Q2 TOS",
        "grading_period_number": 2,
        "classification_mode": "custom",
        "total_items": 40
    });

    let req: CreateTosRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.total_items, 40);
    assert!(req.time_unit.is_none());
}

#[test]
fn test_create_competency_request_optional_code_is_none() {
    let json = serde_json::json!({
        "competency_text": "Identify parts of a sentence",
        "time_units_taught": 3
    });

    let req: CreateCompetencyRequest = serde_json::from_value(json).unwrap();
    assert!(req.competency_code.is_none());
    assert_eq!(req.competency_text, "Identify parts of a sentence");
    assert_eq!(req.time_units_taught, 3);
}

#[test]
fn test_bulk_add_competencies_request_collects_all_items() {
    let json = serde_json::json!({
        "competencies": [
            { "competency_text": "Skill A", "time_units_taught": 2 },
            { "competency_text": "Skill B", "time_units_taught": 1 }
        ]
    });

    let req: BulkAddCompetenciesRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.competencies.len(), 2);
    assert_eq!(req.competencies[0].competency_text, "Skill A");
    assert_eq!(req.competencies[1].time_units_taught, 1);
}

#[test]
fn test_melc_search_response_serializes_empty_list() {
    let response = MelcSearchResponse { melcs: vec![] };
    let json = serde_json::to_value(&response).unwrap();
    assert_eq!(json["melcs"].as_array().unwrap().len(), 0);
}

#[test]
fn test_melc_entry_serializes_correctly() {
    let entry = MelcEntry {
        id: 42,
        subject: "English".to_string(),
        grade_level: "7".to_string(),
        quarter: Some(1),
        competency_code: "ENG7-01".to_string(),
        competency_text: "Read fluently".to_string(),
        domain: Some("Reading".to_string()),
    };

    let json = serde_json::to_value(&entry).unwrap();
    assert_eq!(json["id"], 42);
    assert_eq!(json["subject"], "English");
    assert_eq!(json["grade_level"], "7");
    assert_eq!(json["competency_code"], "ENG7-01");
}

#[test]
fn test_melc_search_response_with_entries_serializes_all() {
    let response = MelcSearchResponse {
        melcs: vec![
            MelcEntry {
                id: 1,
                subject: "Math".to_string(),
                grade_level: "8".to_string(),
                quarter: Some(2),
                competency_code: "".to_string(),
                competency_text: "Solve linear equations".to_string(),
                domain: None,
            },
            MelcEntry {
                id: 2,
                subject: "Science".to_string(),
                grade_level: "8".to_string(),
                quarter: Some(2),
                competency_code: "SCI8-02".to_string(),
                competency_text: "Describe cell division".to_string(),
                domain: Some("Biology".to_string()),
            },
        ],
    };

    let json = serde_json::to_value(&response).unwrap();
    assert_eq!(json["melcs"].as_array().unwrap().len(), 2);
    assert_eq!(json["melcs"][0]["subject"], "Math");
    assert_eq!(json["melcs"][1]["competency_code"], "SCI8-02");
}
