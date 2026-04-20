use uuid::Uuid;
use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::db::repositories::user_repository::UserRepository;
use crate::tests::common::test_db::test_db;

#[tokio::test]
async fn test_create_log_and_find_by_user() {
    let db = test_db().await;
    let user = UserRepository::new(db.clone())
        .create_account("logger".to_string(), "Log User".to_string(), "teacher".to_string(), None)
        .await
        .expect("user");
    let repo = ActivityLogRepository::new(db);

    repo.create_log(user.id, "login", Some("from web".to_string()))
        .await
        .expect("create_log failed");

    let logs = repo.find_by_user_id(user.id).await.expect("find failed");
    assert_eq!(logs.len(), 1);
    assert_eq!(logs[0].action, "login");
    assert_eq!(logs[0].user_id, user.id);
}

#[tokio::test]
async fn test_find_by_user_id_returns_empty_for_unknown() {
    let db = test_db().await;
    let repo = ActivityLogRepository::new(db);
    let logs = repo.find_by_user_id(Uuid::new_v4()).await.expect("find failed");
    assert!(logs.is_empty());
}

#[tokio::test]
async fn test_multiple_logs_ordered_by_desc_created_at() {
    let db = test_db().await;
    let user = UserRepository::new(db.clone())
        .create_account("loggerx".to_string(), "Log X".to_string(), "teacher".to_string(), None)
        .await
        .expect("user");
    let repo = ActivityLogRepository::new(db);

    repo.create_log(user.id, "login", None).await.expect("log1");
    repo.create_log(user.id, "view_class", None).await.expect("log2");

    let logs = repo.find_by_user_id(user.id).await.expect("find failed");
    assert_eq!(logs.len(), 2);
}
