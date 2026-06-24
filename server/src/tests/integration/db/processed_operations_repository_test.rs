use crate::modules::auth::UserRepository;
use crate::modules::sync::service_operations::push::OperationResult;
use crate::modules::sync::ProcessedOperationsRepository;
use crate::tests::common::test_db::test_db;

fn sample_result() -> OperationResult {
    OperationResult {
        id: "op-001".to_string(),
        entity_type: "assignment".to_string(),
        operation: "create".to_string(),
        success: true,
        server_id: Some("server-001".to_string()),
        error: None,
        updated_at: None,
        metadata: None,
    }
}

#[tokio::test]
async fn test_check_processed_returns_none_for_new_op() {
    let db = test_db().await;
    let repo = ProcessedOperationsRepository::new(db);
    let result = repo.check_processed("op-new").await.expect("check failed");
    assert!(result.is_none());
}

#[tokio::test]
async fn test_save_and_check_processed_returns_result() {
    let db = test_db().await;
    let user_id = UserRepository::new(db.clone())
        .create_account(
            "proc_user1".to_string(),
            "Proc".to_string(),
            "One".to_string(),
            "teacher".to_string(),
            None,
        )
        .await
        .expect("user")
        .id;
    let repo = ProcessedOperationsRepository::new(db);
    let op_result = sample_result();

    repo.save_processed("op-001", user_id, "assignment", "create", &op_result)
        .await
        .expect("save failed");

    let found = repo.check_processed("op-001").await.expect("check failed");
    assert!(found.is_some());
    let r = found.unwrap();
    assert_eq!(r.id, "op-001");
    assert!(r.success);
}

#[tokio::test]
async fn test_check_processed_ram_cache_hit() {
    let db = test_db().await;
    let user_id = UserRepository::new(db.clone())
        .create_account(
            "proc_user2".to_string(),
            "Proc".to_string(),
            "Two".to_string(),
            "teacher".to_string(),
            None,
        )
        .await
        .expect("user")
        .id;
    let repo = ProcessedOperationsRepository::new(db);
    let op_result = sample_result();

    repo.save_processed("op-002", user_id, "assignment", "create", &op_result)
        .await
        .expect("save failed");

    // Second call should hit RAM cache
    let found = repo.check_processed("op-002").await.expect("check failed");
    assert!(found.is_some());
}
