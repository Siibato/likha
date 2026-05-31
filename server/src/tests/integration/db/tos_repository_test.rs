use uuid::Uuid;
use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::tos_repository::TosRepository;
use crate::tests::common::test_db::test_db;

#[tokio::test]
async fn test_create_tos_and_find_by_id() {
    let db = test_db().await;
    let class_id = ClassRepository::new(db.clone())
        .create_class("TOS Class".to_string(), None, None, false)
        .await
        .expect("class")
        .id;
    let repo = TosRepository::new(db);
    let tos_id = Uuid::new_v4();

    let tos = repo
        .create_tos(
            tos_id, class_id, 1, "Q1 TOS", "difficulty", 30,
            "days", 50.0, 30.0, 20.0, 16.67, 16.67, 16.67, 16.67, 16.67, 16.67,
        )
        .await
        .expect("create_tos failed");

    assert_eq!(tos.title, "Q1 TOS");
    assert_eq!(tos.class_id, class_id);

    let found = repo.find_tos_by_id(tos_id).await.expect("find failed");
    assert!(found.is_some());
}

#[tokio::test]
async fn test_find_tos_by_class() {
    let db = test_db().await;
    let class_id = ClassRepository::new(db.clone())
        .create_class("TOS Class2".to_string(), None, None, false)
        .await
        .expect("class")
        .id;
    let repo = TosRepository::new(db);

    repo.create_tos(
        Uuid::new_v4(), class_id, 1, "TOS Q1", "blooms", 20,
        "days", 50.0, 30.0, 20.0, 16.67, 16.67, 16.67, 16.67, 16.67, 16.67,
    )
    .await
    .expect("create failed");

    let list = repo.find_tos_by_class(class_id).await.expect("find failed");
    assert_eq!(list.len(), 1);
}

#[tokio::test]
async fn test_find_tos_by_id_returns_none_for_unknown() {
    let db = test_db().await;
    let repo = TosRepository::new(db);
    let found = repo.find_tos_by_id(Uuid::new_v4()).await.expect("find failed");
    assert!(found.is_none());
}
