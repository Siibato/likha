use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::user_repository::UserRepository;
use crate::tests::common::test_db::test_db;

#[tokio::test]
async fn test_create_and_find_class_by_id() {
    let db = test_db().await;
    let repo = ClassRepository::new(db);

    let class = repo
        .create_class("Math 101".to_string(), Some("Basic Math".to_string()), None, false)
        .await
        .expect("create_class failed");

    assert_eq!(class.title, "Math 101");
    assert!(!class.is_archived);

    let found = repo.find_by_id(class.id).await.expect("find_by_id failed");
    assert!(found.is_some());
    assert_eq!(found.unwrap().id, class.id);
}

#[tokio::test]
async fn test_find_by_user_id_returns_empty_when_no_enrollments() {
    let db = test_db().await;
    let user_repo = UserRepository::new(db.clone());
    let class_repo = ClassRepository::new(db);

    let user = user_repo
        .create_account("teacher01".to_string(), "T One".to_string(), "teacher".to_string(), None)
        .await
        .expect("create_account failed");

    let classes = class_repo
        .find_by_user_id(user.id, "teacher")
        .await
        .expect("find_by_user_id failed");

    assert!(classes.is_empty());
}

#[tokio::test]
async fn test_find_by_id_returns_none_for_unknown() {
    let db = test_db().await;
    let repo = ClassRepository::new(db);
    let found = repo
        .find_by_id(uuid::Uuid::new_v4())
        .await
        .expect("find_by_id failed");
    assert!(found.is_none());
}
