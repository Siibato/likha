use uuid::Uuid;
use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::grade_computation_repository::GradeComputationRepository;
use crate::tests::common::test_db::test_db;

#[tokio::test]
async fn test_upsert_config_and_get_config() {
    let db = test_db().await;
    let class_id = ClassRepository::new(db.clone())
        .create_class("GradingClass".to_string(), None, None, false)
        .await
        .expect("class")
        .id;
    let repo = GradeComputationRepository::new(db);

    let config = repo
        .upsert_config(class_id, 1, 30.0, 50.0, 20.0)
        .await
        .expect("upsert_config failed");

    assert_eq!(config.class_id, class_id);
    assert_eq!(config.grading_period_number, Some(1));
    assert!((config.ww_weight - 30.0).abs() < f64::EPSILON);

    let found = repo.get_config(class_id, 1).await.expect("get_config failed");
    assert!(found.is_some());
}

#[tokio::test]
async fn test_upsert_config_updates_on_conflict() {
    let db = test_db().await;
    let class_id = ClassRepository::new(db.clone())
        .create_class("GradingClass2".to_string(), None, None, false)
        .await
        .expect("class")
        .id;
    let repo = GradeComputationRepository::new(db);

    repo.upsert_config(class_id, 1, 30.0, 50.0, 20.0).await.expect("first upsert");
    repo.upsert_config(class_id, 1, 25.0, 55.0, 20.0).await.expect("second upsert");

    let configs = repo.get_all_configs(class_id).await.expect("get_all_configs failed");
    assert_eq!(configs.len(), 1);
    assert!((configs[0].ww_weight - 25.0).abs() < f64::EPSILON);
}

#[tokio::test]
async fn test_get_config_returns_none_for_unknown_class() {
    let db = test_db().await;
    let repo = GradeComputationRepository::new(db);
    let found = repo.get_config(Uuid::new_v4(), 1).await.expect("get_config failed");
    assert!(found.is_none());
}

#[tokio::test]
async fn test_setup_defaults_creates_four_periods() {
    let db = test_db().await;
    let class_id = ClassRepository::new(db.clone())
        .create_class("GradingClass3".to_string(), None, None, false)
        .await
        .expect("class")
        .id;
    let repo = GradeComputationRepository::new(db);

    let configs = repo.setup_defaults(class_id, "language").await.expect("setup_defaults failed");
    assert_eq!(configs.len(), 4);
}
