use crate::db::repositories::user_repository::UserRepository;
use crate::tests::common::test_db::test_db;

#[tokio::test]
async fn test_create_and_find_user_by_id() {
    let db = test_db().await;
    let repo = UserRepository::new(db);

    let user = repo
        .create_account("alice".to_string(), "Alice Smith".to_string(), "teacher".to_string(), None)
        .await
        .expect("create_account failed");

    assert_eq!(user.username, "alice");
    assert_eq!(user.full_name, "Alice Smith");
    assert_eq!(user.role, "teacher");
    assert_eq!(user.account_status, "pending_activation");

    let found = repo.find_by_id(user.id).await.expect("find_by_id failed");
    assert!(found.is_some());
    assert_eq!(found.unwrap().id, user.id);
}

#[tokio::test]
async fn test_find_by_username() {
    let db = test_db().await;
    let repo = UserRepository::new(db);

    repo.create_account("bob".to_string(), "Bob Jones".to_string(), "student".to_string(), None)
        .await
        .expect("create_account failed");

    let found = repo.find_by_username("bob").await.expect("find_by_username failed");
    assert!(found.is_some());
    assert_eq!(found.unwrap().username, "bob");
}

#[tokio::test]
async fn test_find_by_username_returns_none_for_unknown() {
    let db = test_db().await;
    let repo = UserRepository::new(db);

    let found = repo.find_by_username("nobody").await.expect("find_by_username failed");
    assert!(found.is_none());
}

#[tokio::test]
async fn test_update_account_status() {
    let db = test_db().await;
    let repo = UserRepository::new(db);

    let user = repo
        .create_account("carol".to_string(), "Carol Lee".to_string(), "teacher".to_string(), None)
        .await
        .expect("create_account failed");

    let updated = repo
        .update_account_status(user.id, "activated")
        .await
        .expect("update_account_status failed");

    assert_eq!(updated.account_status, "activated");
}
