use crate::schema::assignment_schema::{
    CreateAssignmentRequest, GradeSubmissionRequest, SubmitTextRequest, UpdateAssignmentRequest,
};

// ===== CreateAssignmentRequest =====

#[test]
fn test_create_assignment_request_deserializes_required_fields() {
    let json = r#"{
        "title": "HW 1",
        "instructions": "Do it",
        "total_points": 100,
        "due_at": "2024-06-01T23:59:00"
    }"#;
    let req: CreateAssignmentRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.title, "HW 1");
    assert_eq!(req.total_points, 100);
    assert_eq!(req.due_at, "2024-06-01T23:59:00");
}

#[test]
fn test_create_assignment_request_boolean_defaults_to_false() {
    let json = r#"{
        "title": "HW 2",
        "instructions": "Read",
        "total_points": 50,
        "due_at": "2024-06-01T00:00:00"
    }"#;
    let req: CreateAssignmentRequest = serde_json::from_str(json).unwrap();
    assert!(!req.allows_text_submission);
    assert!(!req.allows_file_submission);
}

#[test]
fn test_create_assignment_request_optional_fields_absent_are_none() {
    let json = r#"{
        "title": "HW 3",
        "instructions": "Submit",
        "total_points": 25,
        "due_at": "2024-06-01T00:00:00"
    }"#;
    let req: CreateAssignmentRequest = serde_json::from_str(json).unwrap();
    assert!(req.allowed_file_types.is_none());
    assert!(req.max_file_size_mb.is_none());
    assert!(req.grading_period_number.is_none());
    assert!(req.component.is_none());
}

#[test]
fn test_create_assignment_request_with_all_fields() {
    let json = r#"{
        "title": "HW 4",
        "instructions": "Full",
        "total_points": 100,
        "allows_text_submission": true,
        "allows_file_submission": true,
        "allowed_file_types": "pdf,docx",
        "max_file_size_mb": 10,
        "due_at": "2024-06-01T00:00:00",
        "is_published": true,
        "grading_period_number": 1,
        "component": "written_work"
    }"#;
    let req: CreateAssignmentRequest = serde_json::from_str(json).unwrap();
    assert!(req.allows_text_submission);
    assert!(req.allows_file_submission);
    assert_eq!(req.allowed_file_types.as_deref(), Some("pdf,docx"));
    assert_eq!(req.max_file_size_mb, Some(10));
    assert_eq!(req.grading_period_number, Some(1));
    assert_eq!(req.component.as_deref(), Some("written_work"));
}

// ===== UpdateAssignmentRequest =====

#[test]
fn test_update_assignment_request_all_fields_optional() {
    let json = r#"{}"#;
    let req: UpdateAssignmentRequest = serde_json::from_str(json).unwrap();
    assert!(req.title.is_none());
    assert!(req.total_points.is_none());
    assert!(req.due_at.is_none());
}

#[test]
fn test_update_assignment_request_partial_update() {
    let json = r#"{"title":"New Title","total_points":75}"#;
    let req: UpdateAssignmentRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.title.as_deref(), Some("New Title"));
    assert_eq!(req.total_points, Some(75));
    assert!(req.due_at.is_none());
}

// ===== GradeSubmissionRequest =====

#[test]
fn test_grade_submission_request_deserializes() {
    let json = r#"{"score": 85, "feedback": "Good work"}"#;
    let req: GradeSubmissionRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.score, 85);
    assert_eq!(req.feedback.as_deref(), Some("Good work"));
}

#[test]
fn test_grade_submission_request_feedback_optional() {
    let json = r#"{"score": 70}"#;
    let req: GradeSubmissionRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.score, 70);
    assert!(req.feedback.is_none());
}

// ===== SubmitTextRequest =====

#[test]
fn test_submit_text_request_with_content() {
    let json = r#"{"text_content": "My answer here"}"#;
    let req: SubmitTextRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.text_content.as_deref(), Some("My answer here"));
}

#[test]
fn test_submit_text_request_content_optional() {
    let json = r#"{}"#;
    let req: SubmitTextRequest = serde_json::from_str(json).unwrap();
    assert!(req.text_content.is_none());
}
