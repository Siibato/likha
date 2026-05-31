use crate::schema::tos_schema::{
    BulkAddCompetenciesRequest, CreateCompetencyRequest, CreateTosRequest, UpdateTosRequest,
};

// ===== CreateTosRequest =====

#[test]
fn test_create_tos_request_required_fields() {
    let json = r#"{
        "title": "Q1 TOS",
        "grading_period_number": 1,
        "classification_mode": "difficulty",
        "total_items": 40
    }"#;
    let req: CreateTosRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.title, "Q1 TOS");
    assert_eq!(req.grading_period_number, 1);
    assert_eq!(req.classification_mode, "difficulty");
    assert_eq!(req.total_items, 40);
}

#[test]
fn test_create_tos_request_optional_fields_default_to_none() {
    let json = r#"{
        "title": "Q2 TOS",
        "grading_period_number": 2,
        "classification_mode": "bloom",
        "total_items": 60
    }"#;
    let req: CreateTosRequest = serde_json::from_str(json).unwrap();
    assert!(req.time_unit.is_none());
    assert!(req.easy_percentage.is_none());
    assert!(req.medium_percentage.is_none());
    assert!(req.hard_percentage.is_none());
    assert!(req.remembering_percentage.is_none());
    assert!(req.creating_percentage.is_none());
}

#[test]
fn test_create_tos_request_with_all_optional_fields() {
    let json = r#"{
        "title": "Q3 TOS",
        "grading_period_number": 3,
        "classification_mode": "difficulty",
        "total_items": 50,
        "time_unit": "weeks",
        "easy_percentage": 40.0,
        "medium_percentage": 40.0,
        "hard_percentage": 20.0
    }"#;
    let req: CreateTosRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.time_unit.as_deref(), Some("weeks"));
    assert_eq!(req.easy_percentage, Some(40.0));
    assert_eq!(req.hard_percentage, Some(20.0));
}

#[test]
fn test_create_tos_request_rejects_missing_required_field() {
    let json = r#"{
        "grading_period_number": 1,
        "classification_mode": "difficulty",
        "total_items": 40
    }"#;
    let result: Result<CreateTosRequest, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

// ===== UpdateTosRequest =====

#[test]
fn test_update_tos_request_all_fields_optional() {
    let json = r#"{}"#;
    let req: UpdateTosRequest = serde_json::from_str(json).unwrap();
    assert!(req.title.is_none());
    assert!(req.classification_mode.is_none());
    assert!(req.total_items.is_none());
}

#[test]
fn test_update_tos_request_partial_update() {
    let json = r#"{"title": "Updated TOS", "total_items": 45}"#;
    let req: UpdateTosRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.title.as_deref(), Some("Updated TOS"));
    assert_eq!(req.total_items, Some(45));
    assert!(req.classification_mode.is_none());
}

// ===== CreateCompetencyRequest =====

#[test]
fn test_create_competency_request_required_fields() {
    let json = r#"{
        "competency_text": "The learner demonstrates understanding...",
        "time_units_taught": 5
    }"#;
    let req: CreateCompetencyRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.competency_text, "The learner demonstrates understanding...");
    assert_eq!(req.time_units_taught, 5);
    assert!(req.competency_code.is_none());
}

#[test]
fn test_create_competency_request_with_code() {
    let json = r#"{
        "competency_code": "M7NS-Ia-1",
        "competency_text": "Describes well-defined sets...",
        "time_units_taught": 3,
        "order_index": 0
    }"#;
    let req: CreateCompetencyRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.competency_code.as_deref(), Some("M7NS-Ia-1"));
    assert_eq!(req.order_index, Some(0));
}

// ===== BulkAddCompetenciesRequest =====

#[test]
fn test_bulk_add_competencies_request_empty_list() {
    let json = r#"{"competencies": []}"#;
    let req: BulkAddCompetenciesRequest = serde_json::from_str(json).unwrap();
    assert!(req.competencies.is_empty());
}

#[test]
fn test_bulk_add_competencies_request_multiple_items() {
    let json = r#"{
        "competencies": [
            {"competency_text": "Competency 1", "time_units_taught": 3},
            {"competency_text": "Competency 2", "time_units_taught": 5}
        ]
    }"#;
    let req: BulkAddCompetenciesRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.competencies.len(), 2);
    assert_eq!(req.competencies[0].time_units_taught, 3);
}
