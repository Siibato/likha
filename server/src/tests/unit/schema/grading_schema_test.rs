use crate::schema::grading_schema::{
    BulkUpdateScoresRequest, CreateGradeItemRequest, OverrideScoreRequest,
    SetupGradingConfigRequest, StudentScore, UpdateGradingConfigRequest,
};
use uuid::Uuid;

// ===== SetupGradingConfigRequest =====

#[test]
fn test_setup_grading_config_request_deserializes() {
    let json = r#"{
        "grade_level": "Grade 7",
        "subject_group": "math_sci",
        "school_year": "2024-2025"
    }"#;
    let req: SetupGradingConfigRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.grade_level, "Grade 7");
    assert_eq!(req.subject_group, "math_sci");
    assert_eq!(req.school_year, "2024-2025");
    assert!(req.semester.is_none());
}

#[test]
fn test_setup_grading_config_request_with_semester() {
    let json = r#"{
        "grade_level": "Grade 11",
        "subject_group": "shs_core",
        "school_year": "2024-2025",
        "semester": 1
    }"#;
    let req: SetupGradingConfigRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.semester, Some(1));
}

// ===== UpdateGradingConfigRequest =====

#[test]
fn test_update_grading_config_request_deserializes() {
    let json = r#"{
        "grading_period_number": 1,
        "ww_weight": 30.0,
        "pt_weight": 50.0,
        "qa_weight": 20.0
    }"#;
    let req: UpdateGradingConfigRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.grading_period_number, 1);
    assert!((req.ww_weight - 30.0).abs() < 0.001);
    assert!((req.pt_weight - 50.0).abs() < 0.001);
    assert!((req.qa_weight - 20.0).abs() < 0.001);
}

#[test]
fn test_update_grading_config_weights_sum_to_100() {
    let json = r#"{
        "grading_period_number": 2,
        "ww_weight": 40.0,
        "pt_weight": 40.0,
        "qa_weight": 20.0
    }"#;
    let req: UpdateGradingConfigRequest = serde_json::from_str(json).unwrap();
    let sum = req.ww_weight + req.pt_weight + req.qa_weight;
    assert!((sum - 100.0).abs() < 0.001);
}

// ===== CreateGradeItemRequest =====

#[test]
fn test_create_grade_item_request_deserializes() {
    let json = r#"{
        "title": "Long Quiz 1",
        "component": "written_work",
        "total_points": 50.0
    }"#;
    let req: CreateGradeItemRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.title, "Long Quiz 1");
    assert_eq!(req.component, "written_work");
    assert!((req.total_points - 50.0).abs() < 0.001);
    assert!(req.grading_period_number.is_none());
}

#[test]
fn test_create_grade_item_request_with_period() {
    let json = r#"{
        "title": "Performance Task",
        "component": "performance_task",
        "grading_period_number": 3,
        "total_points": 100.0
    }"#;
    let req: CreateGradeItemRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.grading_period_number, Some(3));
    assert_eq!(req.component, "performance_task");
}

// ===== BulkUpdateScoresRequest =====

#[test]
fn test_bulk_update_scores_request_deserializes() {
    let id = Uuid::new_v4();
    let json = format!(
        r#"{{"scores":[{{"student_id":"{}","score":85.0}}]}}"#,
        id
    );
    let req: BulkUpdateScoresRequest = serde_json::from_str(&json).unwrap();
    assert_eq!(req.scores.len(), 1);
    assert_eq!(req.scores[0].student_id, id);
    assert!((req.scores[0].score - 85.0).abs() < 0.001);
}

#[test]
fn test_bulk_update_scores_request_empty_list() {
    let json = r#"{"scores":[]}"#;
    let req: BulkUpdateScoresRequest = serde_json::from_str(json).unwrap();
    assert!(req.scores.is_empty());
}

// ===== StudentScore =====

#[test]
fn test_student_score_deserializes() {
    let id = Uuid::new_v4();
    let json = format!(r#"{{"student_id":"{}","score":92.5}}"#, id);
    let score: StudentScore = serde_json::from_str(&json).unwrap();
    assert_eq!(score.student_id, id);
    assert!((score.score - 92.5).abs() < 0.001);
}

// ===== OverrideScoreRequest =====

#[test]
fn test_override_score_request_deserializes() {
    let json = r#"{"override_score": 95.0}"#;
    let req: OverrideScoreRequest = serde_json::from_str(json).unwrap();
    assert!((req.override_score - 95.0).abs() < 0.001);
}

#[test]
fn test_override_score_request_zero_value() {
    let json = r#"{"override_score": 0.0}"#;
    let req: OverrideScoreRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.override_score, 0.0);
}
