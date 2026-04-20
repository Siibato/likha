use crate::db::repositories::class_repository::ClassRepository;
use crate::services::grade_computation::grade_computation_service::GradeComputationService;
use crate::tests::common::test_db::test_db;

#[tokio::test]
async fn test_setup_class_grade_config() {
    let db = test_db().await;
    let class_id = ClassRepository::new(db.clone())
        .create_class("Grade Class".to_string(), None, None, false)
        .await
        .expect("class")
        .id;
    let service = GradeComputationService::new(db);

    let configs = service
        .repo
        .setup_defaults(class_id, "language")
        .await
        .expect("setup_defaults failed");

    assert_eq!(configs.len(), 4);
    for config in &configs {
        let total = config.ww_weight + config.pt_weight + config.qa_weight;
        assert!((total - 100.0).abs() < 0.01, "Weights should sum to 100, got {}", total);
    }
}

#[tokio::test]
async fn test_get_grade_items_returns_empty_for_fresh_class() {
    let db = test_db().await;
    let class_id = ClassRepository::new(db.clone())
        .create_class("Grade Class 2".to_string(), None, None, false)
        .await
        .expect("class")
        .id;
    let service = GradeComputationService::new(db);

    let items = service
        .get_grade_items(class_id, 1)
        .await
        .expect("get_grade_items failed");
    assert!(items.is_empty());
}
