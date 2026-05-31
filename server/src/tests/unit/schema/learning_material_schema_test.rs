use crate::schema::learning_material_schema::{
    CreateMaterialRequest, ReorderMaterialRequest, ReorderMaterialsRequest, UpdateMaterialRequest,
};

// ===== CreateMaterialRequest =====

#[test]
fn test_create_material_request_required_title() {
    let json = r#"{"title": "Lesson 1 - Introduction"}"#;
    let req: CreateMaterialRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.title, "Lesson 1 - Introduction");
    assert!(req.description.is_none());
    assert!(req.content_text.is_none());
}

#[test]
fn test_create_material_request_with_all_fields() {
    let json = r#"{
        "title": "Lesson 2",
        "description": "A comprehensive lesson",
        "content_text": "This lesson covers..."
    }"#;
    let req: CreateMaterialRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.title, "Lesson 2");
    assert_eq!(req.description.as_deref(), Some("A comprehensive lesson"));
    assert_eq!(req.content_text.as_deref(), Some("This lesson covers..."));
}

#[test]
fn test_create_material_request_rejects_missing_title() {
    let json = r#"{"description": "no title"}"#;
    let result: Result<CreateMaterialRequest, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

#[test]
fn test_create_material_request_empty_string_title_is_accepted() {
    let json = r#"{"title": ""}"#;
    let req: CreateMaterialRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.title, "");
}

// ===== UpdateMaterialRequest =====

#[test]
fn test_update_material_request_all_fields_optional() {
    let json = r#"{}"#;
    let req: UpdateMaterialRequest = serde_json::from_str(json).unwrap();
    assert!(req.title.is_none());
    assert!(req.description.is_none());
    assert!(req.content_text.is_none());
}

#[test]
fn test_update_material_request_partial_update() {
    let json = r#"{"title": "Updated Lesson", "content_text": "New content"}"#;
    let req: UpdateMaterialRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.title.as_deref(), Some("Updated Lesson"));
    assert_eq!(req.content_text.as_deref(), Some("New content"));
    assert!(req.description.is_none());
}

// ===== ReorderMaterialRequest =====

#[test]
fn test_reorder_material_request_valid() {
    let json = r#"{"new_order_index": 3}"#;
    let req: ReorderMaterialRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.new_order_index, 3);
}

#[test]
fn test_reorder_material_request_zero_index() {
    let json = r#"{"new_order_index": 0}"#;
    let req: ReorderMaterialRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.new_order_index, 0);
}

#[test]
fn test_reorder_material_request_rejects_missing_field() {
    let json = r#"{}"#;
    let result: Result<ReorderMaterialRequest, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

// ===== ReorderMaterialsRequest =====

#[test]
fn test_reorder_materials_request_empty_list() {
    let json = r#"{"material_ids": []}"#;
    let req: ReorderMaterialsRequest = serde_json::from_str(json).unwrap();
    assert!(req.material_ids.is_empty());
}

#[test]
fn test_reorder_materials_request_multiple_ids() {
    let json = r#"{
        "material_ids": [
            "550e8400-e29b-41d4-a716-446655440001",
            "550e8400-e29b-41d4-a716-446655440002"
        ]
    }"#;
    let req: ReorderMaterialsRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.material_ids.len(), 2);
}

#[test]
fn test_reorder_materials_request_rejects_invalid_uuid() {
    let json = r#"{"material_ids": ["not-a-uuid"]}"#;
    let result: Result<ReorderMaterialsRequest, _> = serde_json::from_str(json);
    assert!(result.is_err());
}
