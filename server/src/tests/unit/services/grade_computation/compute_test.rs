use std::collections::HashMap;
use uuid::Uuid;

use crate::services::grade_computation::compute::compute_component;

fn make_item(id: Uuid, total_points: f64) -> ::entity::grade_items::Model {
    ::entity::grade_items::Model {
        id,
        class_id: Uuid::new_v4(),
        title: "Test Item".to_string(),
        component: "written_work".to_string(),
        grading_period_number: Some(1),
        total_points,
        source_type: "assignment".to_string(),
        source_id: None,
        order_index: 0,
        created_at: chrono::Utc::now().naive_utc(),
        updated_at: chrono::Utc::now().naive_utc(),
        deleted_at: None,
    }
}

#[test]
fn test_compute_component_empty_items_returns_zero() {
    let score_map: HashMap<Uuid, f64> = HashMap::new();
    let (percentage, weighted) = compute_component(&[], &score_map, 30.0);
    assert_eq!(percentage, 0.0);
    assert_eq!(weighted, 0.0);
}

#[test]
fn test_compute_component_all_items_scored_full_marks() {
    let id = Uuid::new_v4();
    let item = make_item(id, 100.0);
    let mut score_map = HashMap::new();
    score_map.insert(id, 100.0);

    let (percentage, weighted) = compute_component(&[&item], &score_map, 30.0);
    assert!((percentage - 100.0).abs() < 0.001);
    assert!((weighted - 30.0).abs() < 0.001);
}

#[test]
fn test_compute_component_partial_score() {
    let id = Uuid::new_v4();
    let item = make_item(id, 100.0);
    let mut score_map = HashMap::new();
    score_map.insert(id, 80.0);

    let (percentage, weighted) = compute_component(&[&item], &score_map, 50.0);
    assert!((percentage - 80.0).abs() < 0.001);
    assert!((weighted - 40.0).abs() < 0.001);
}

#[test]
fn test_compute_component_missing_score_still_counts_total_points() {
    let id1 = Uuid::new_v4();
    let id2 = Uuid::new_v4();
    let item1 = make_item(id1, 100.0);
    let item2 = make_item(id2, 100.0);

    let mut score_map = HashMap::new();
    score_map.insert(id1, 80.0);
    // id2 has no score — its total_points still go into denominator

    let (percentage, weighted) = compute_component(&[&item1, &item2], &score_map, 30.0);
    // 80 / 200 * 100 = 40%
    assert!((percentage - 40.0).abs() < 0.001);
    assert!((weighted - 12.0).abs() < 0.001);
}

#[test]
fn test_compute_component_zero_total_points_no_panic() {
    let id = Uuid::new_v4();
    let item = make_item(id, 0.0);
    let mut score_map = HashMap::new();
    score_map.insert(id, 0.0);

    let (percentage, weighted) = compute_component(&[&item], &score_map, 30.0);
    assert_eq!(percentage, 0.0);
    assert_eq!(weighted, 0.0);
}

#[test]
fn test_compute_component_weight_applied_correctly() {
    let id = Uuid::new_v4();
    let item = make_item(id, 50.0);
    let mut score_map = HashMap::new();
    score_map.insert(id, 50.0); // 100%

    let (percentage, weighted) = compute_component(&[&item], &score_map, 20.0);
    assert!((percentage - 100.0).abs() < 0.001);
    assert!((weighted - 20.0).abs() < 0.001);
}

#[test]
fn test_compute_component_multiple_items_all_scored() {
    let id1 = Uuid::new_v4();
    let id2 = Uuid::new_v4();
    let item1 = make_item(id1, 100.0);
    let item2 = make_item(id2, 100.0);

    let mut score_map = HashMap::new();
    score_map.insert(id1, 80.0);
    score_map.insert(id2, 60.0);

    let (percentage, weighted) = compute_component(&[&item1, &item2], &score_map, 40.0);
    // (80 + 60) / 200 * 100 = 70%
    assert!((percentage - 70.0).abs() < 0.001);
    assert!((weighted - 28.0).abs() < 0.001);
}

#[test]
fn test_compute_component_no_items_scored_returns_zero_percentage() {
    let id1 = Uuid::new_v4();
    let id2 = Uuid::new_v4();
    let item1 = make_item(id1, 100.0);
    let item2 = make_item(id2, 100.0);

    let score_map: HashMap<Uuid, f64> = HashMap::new(); // no scores at all

    let (percentage, weighted) = compute_component(&[&item1, &item2], &score_map, 30.0);
    // 0 / 200 * 100 = 0%
    assert_eq!(percentage, 0.0);
    assert_eq!(weighted, 0.0);
}
