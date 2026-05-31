use uuid::Uuid;
use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::tos_repository::TosRepository;
use crate::db::repositories::user_repository::UserRepository;
use crate::tests::common::test_db::test_db;

/// Helper: create a class + teacher participant so TOS CRUD auth checks pass
async fn setup_teacher_class(db: &sea_orm::DatabaseConnection) -> (Uuid, Uuid) {
    let user_repo = UserRepository::new(db.clone());
    let class_repo = ClassRepository::new(db.clone());

    let teacher = user_repo
        .create_account("tos_teacher".to_string(), "TOS Teacher".to_string(), "teacher".to_string(), None)
        .await
        .expect("teacher");

    let class = class_repo
        .create_class("TOS Service Class".to_string(), None, None, false)
        .await
        .expect("class");

    class_repo
        .add_participant(class.id, teacher.id)
        .await
        .expect("add_participant");

    (teacher.id, class.id)
}

#[tokio::test]
async fn test_tos_repo_create_and_find_by_class() {
    let db = test_db().await;
    let (_, class_id) = setup_teacher_class(&db).await;
    let repo = TosRepository::new(db);

    repo.create_tos(
        Uuid::new_v4(), class_id, 1, "Service TOS", "difficulty", 20,
        "days", 50.0, 30.0, 20.0, 16.67, 16.67, 16.67, 16.67, 16.67, 16.67,
    )
    .await
    .expect("create_tos failed");

    let list = repo.find_tos_by_class(class_id).await.expect("find failed");
    assert_eq!(list.len(), 1);
    assert_eq!(list[0].title, "Service TOS");
}

#[tokio::test]
async fn test_tos_unique_per_class_period() {
    let db = test_db().await;
    let (_, class_id) = setup_teacher_class(&db).await;
    let repo = TosRepository::new(db);

    // First TOS for period 1
    repo.create_tos(
        Uuid::new_v4(), class_id, 1, "TOS Q1", "blooms", 30,
        "days", 50.0, 30.0, 20.0, 16.67, 16.67, 16.67, 16.67, 16.67, 16.67,
    )
    .await
    .expect("first create");

    // Second TOS for same class/period should fail (UNIQUE constraint)
    let result = repo.create_tos(
        Uuid::new_v4(), class_id, 1, "TOS Q1 Duplicate", "difficulty", 30,
        "days", 50.0, 30.0, 20.0, 16.67, 16.67, 16.67, 16.67, 16.67, 16.67,
    )
    .await;

    assert!(result.is_err());
}
