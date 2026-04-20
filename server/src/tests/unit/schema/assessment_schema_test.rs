use crate::schema::assessment_schema::{
    AddQuestionRequest, AddQuestionsRequest, ChoiceInput, CreateAssessmentRequest,
    UpdateAssessmentRequest,
};

// ===== CreateAssessmentRequest =====

#[test]
fn test_create_assessment_request_deserializes_required_fields() {
    let json = r#"{
        "title": "Quiz 1",
        "time_limit_minutes": 30,
        "open_at": "2024-06-01T08:00:00",
        "close_at": "2024-06-01T09:00:00"
    }"#;
    let req: CreateAssessmentRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.title, "Quiz 1");
    assert_eq!(req.time_limit_minutes, 30);
    assert_eq!(req.open_at, "2024-06-01T08:00:00");
    assert_eq!(req.close_at, "2024-06-01T09:00:00");
}

#[test]
fn test_create_assessment_request_optional_fields_absent_are_none() {
    let json = r#"{
        "title": "Quiz 2",
        "time_limit_minutes": 60,
        "open_at": "2024-06-01T08:00:00",
        "close_at": "2024-06-02T08:00:00"
    }"#;
    let req: CreateAssessmentRequest = serde_json::from_str(json).unwrap();
    assert!(req.description.is_none());
    assert!(req.show_results_immediately.is_none());
    assert!(req.questions.is_none());
    assert!(req.grading_period_number.is_none());
    assert!(req.component.is_none());
    assert!(req.tos_id.is_none());
}

#[test]
fn test_create_assessment_request_with_description_and_component() {
    let json = r#"{
        "title": "Midterm",
        "description": "Covers chapters 1-5",
        "time_limit_minutes": 90,
        "open_at": "2024-06-01T08:00:00",
        "close_at": "2024-06-01T10:30:00",
        "grading_period_number": 2,
        "component": "quarterly_assessment"
    }"#;
    let req: CreateAssessmentRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.description.as_deref(), Some("Covers chapters 1-5"));
    assert_eq!(req.grading_period_number, Some(2));
    assert_eq!(req.component.as_deref(), Some("quarterly_assessment"));
}

// ===== UpdateAssessmentRequest =====

#[test]
fn test_update_assessment_request_all_optional_empty_object() {
    let json = r#"{}"#;
    let req: UpdateAssessmentRequest = serde_json::from_str(json).unwrap();
    assert!(req.title.is_none());
    assert!(req.time_limit_minutes.is_none());
    assert!(req.open_at.is_none());
    assert!(req.close_at.is_none());
}

#[test]
fn test_update_assessment_request_partial_fields() {
    let json = r#"{"title":"Updated Quiz","time_limit_minutes":45}"#;
    let req: UpdateAssessmentRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.title.as_deref(), Some("Updated Quiz"));
    assert_eq!(req.time_limit_minutes, Some(45));
    assert!(req.description.is_none());
}

// ===== AddQuestionRequest =====

#[test]
fn test_add_question_request_multiple_choice() {
    let json = r#"{
        "question_type": "multiple_choice",
        "question_text": "What is 2+2?",
        "points": 5,
        "order_index": 0,
        "choices": [
            {"choice_text": "3", "is_correct": false, "order_index": 0},
            {"choice_text": "4", "is_correct": true, "order_index": 1}
        ]
    }"#;
    let req: AddQuestionRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.question_type, "multiple_choice");
    assert_eq!(req.points, 5);
    let choices = req.choices.unwrap();
    assert_eq!(choices.len(), 2);
    assert!(choices[1].is_correct);
}

#[test]
fn test_add_question_request_essay_no_choices() {
    let json = r#"{
        "question_type": "essay",
        "question_text": "Explain photosynthesis.",
        "points": 10,
        "order_index": 1
    }"#;
    let req: AddQuestionRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.question_type, "essay");
    assert!(req.choices.is_none());
    assert!(req.correct_answers.is_none());
}

// ===== AddQuestionsRequest =====

#[test]
fn test_add_questions_request_wraps_list() {
    let json = r#"{
        "questions": [
            {
                "question_type": "identification",
                "question_text": "Name the capital of France.",
                "points": 2,
                "order_index": 0
            }
        ]
    }"#;
    let req: AddQuestionsRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.questions.len(), 1);
    assert_eq!(req.questions[0].question_type, "identification");
}

// ===== ChoiceInput =====

#[test]
fn test_choice_input_deserializes() {
    let json = r#"{"choice_text":"Option A","is_correct":true,"order_index":0}"#;
    let choice: ChoiceInput = serde_json::from_str(json).unwrap();
    assert_eq!(choice.choice_text, "Option A");
    assert!(choice.is_correct);
    assert_eq!(choice.order_index, 0);
}
