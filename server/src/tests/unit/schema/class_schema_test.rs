use crate::schema::class_schema::{
    AddStudentRequest, CreateClassRequest, UpdateClassRequest,
};

// ===== CreateClassRequest =====

#[test]
fn test_create_class_request_required_title() {
    let json = r#"{"title": "Grade 7 - Rizal"}"#;
    let req: CreateClassRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.title, "Grade 7 - Rizal");
    assert!(req.description.is_none());
    assert!(req.teacher_id.is_none());
    assert!(req.is_advisory.is_none());
}

#[test]
fn test_create_class_request_with_all_fields() {
    let json = r#"{
        "title": "Grade 8 - Bonifacio",
        "description": "Section for Grade 8",
        "teacher_id": "550e8400-e29b-41d4-a716-446655440000",
        "is_advisory": true
    }"#;
    let req: CreateClassRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.title, "Grade 8 - Bonifacio");
    assert_eq!(req.description.as_deref(), Some("Section for Grade 8"));
    assert!(req.teacher_id.is_some());
    assert_eq!(req.is_advisory, Some(true));
}

#[test]
fn test_create_class_request_rejects_missing_title() {
    let json = r#"{"description": "No title provided"}"#;
    let result: Result<CreateClassRequest, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

#[test]
fn test_create_class_request_invalid_uuid_fails() {
    let json = r#"{"title": "Test", "teacher_id": "not-a-uuid"}"#;
    let result: Result<CreateClassRequest, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

// ===== UpdateClassRequest =====

#[test]
fn test_update_class_request_all_fields_optional() {
    let json = r#"{}"#;
    let req: UpdateClassRequest = serde_json::from_str(json).unwrap();
    assert!(req.title.is_none());
    assert!(req.description.is_none());
    assert!(req.teacher_id.is_none());
    assert!(req.is_advisory.is_none());
}

#[test]
fn test_update_class_request_partial_update() {
    let json = r#"{"title": "New Title", "is_advisory": false}"#;
    let req: UpdateClassRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.title.as_deref(), Some("New Title"));
    assert_eq!(req.is_advisory, Some(false));
    assert!(req.description.is_none());
    assert!(req.teacher_id.is_none());
}

#[test]
fn test_update_class_request_with_teacher_id() {
    let json = r#"{"teacher_id": "550e8400-e29b-41d4-a716-446655440000"}"#;
    let req: UpdateClassRequest = serde_json::from_str(json).unwrap();
    assert!(req.teacher_id.is_some());
}

// ===== AddStudentRequest =====

#[test]
fn test_add_student_request_valid_uuid() {
    let json = r#"{"student_id": "550e8400-e29b-41d4-a716-446655440001"}"#;
    let req: AddStudentRequest = serde_json::from_str(json).unwrap();
    assert_eq!(
        req.student_id.to_string(),
        "550e8400-e29b-41d4-a716-446655440001"
    );
}

#[test]
fn test_add_student_request_rejects_invalid_uuid() {
    let json = r#"{"student_id": "not-a-uuid"}"#;
    let result: Result<AddStudentRequest, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

#[test]
fn test_add_student_request_rejects_missing_field() {
    let json = r#"{}"#;
    let result: Result<AddStudentRequest, _> = serde_json::from_str(json);
    assert!(result.is_err());
}
