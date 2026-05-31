use chrono::Utc;
use crate::db::repositories::assignment_repository::AssignmentRepository;
use crate::db::repositories::class_repository::ClassRepository;
use crate::tests::common::test_db::test_db;

async fn create_test_class(db: &sea_orm::DatabaseConnection) -> uuid::Uuid {
    let repo = ClassRepository::new(db.clone());
    let class = repo
        .create_class("Test Class".to_string(), None, None, false)
        .await
        .expect("create_class failed");
    class.id
}

#[tokio::test]
async fn test_create_and_find_assignment() {
    let db = test_db().await;
    let class_id = create_test_class(&db).await;
    let repo = AssignmentRepository::new(db);

    let due_at = Utc::now().naive_utc();
    let assignment = repo
        .create_assignment(
            class_id,
            "HW 1".to_string(),
            "Do the exercises".to_string(),
            100,
            true,
            false,
            None,
            None,
            due_at,
            0,
            None,
            true,
            Some(1),
            Some("WW".to_string()),
        )
        .await
        .expect("create_assignment failed");

    assert_eq!(assignment.title, "HW 1");
    assert_eq!(assignment.class_id, class_id);
    assert!(assignment.is_published);

    let found = repo
        .find_by_id(assignment.id)
        .await
        .expect("find_by_id failed");
    assert!(found.is_some());
}

#[tokio::test]
async fn test_find_by_class_id_returns_assignments() {
    let db = test_db().await;
    let class_id = create_test_class(&db).await;
    let repo = AssignmentRepository::new(db);

    let due_at = Utc::now().naive_utc();
    repo.create_assignment(
        class_id, "A1".to_string(), "".to_string(), 50,
        true, false, None, None, due_at, 0, None, true, None, None,
    )
    .await
    .expect("create failed");

    let list = repo
        .find_by_class_id(class_id)
        .await
        .expect("find_by_class_id failed");
    assert_eq!(list.len(), 1);
}

#[tokio::test]
async fn test_find_published_excludes_unpublished() {
    let db = test_db().await;
    let class_id = create_test_class(&db).await;
    let repo = AssignmentRepository::new(db);

    let due_at = Utc::now().naive_utc();
    repo.create_assignment(
        class_id, "Published".to_string(), "".to_string(), 50,
        true, false, None, None, due_at, 0, None, true, None, None,
    )
    .await
    .expect("create published failed");

    repo.create_assignment(
        class_id, "Draft".to_string(), "".to_string(), 50,
        true, false, None, None, due_at, 1, None, false, None, None,
    )
    .await
    .expect("create draft failed");

    let all = repo.find_by_class_id(class_id).await.expect("find all failed");
    let published = repo.find_published_by_class_id(class_id).await.expect("find published failed");
    assert_eq!(all.len(), 2);
    assert_eq!(published.len(), 1);
    assert_eq!(published[0].title, "Published");
}
