use chrono::Utc;
use uuid::Uuid;
use crate::db::repositories::assignment_repository::AssignmentRepository;
use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::user_repository::UserRepository;
use crate::tests::common::test_db::test_db;

/// Integration test that mimics a "create assignment" sync push operation
/// by directly exercising the repositories, verifying the data lands in the DB.
#[tokio::test]
async fn test_sync_create_assignment_lands_in_db() {
    let db = test_db().await;

    // Create prerequisite data
    let user = UserRepository::new(db.clone())
        .create_account("sync_teacher".to_string(), "Sync Teacher".to_string(), "teacher".to_string(), None)
        .await
        .expect("user");

    let class = ClassRepository::new(db.clone())
        .create_class("Sync Class".to_string(), None, None, false)
        .await
        .expect("class");

    ClassRepository::new(db.clone())
        .add_participant(class.id, user.id)
        .await
        .expect("participant");

    // Simulate the assignment create op from the mobile client
    let client_id = Uuid::new_v4();
    let due_at = Utc::now().naive_utc();
    let assignment = AssignmentRepository::new(db.clone())
        .create_assignment(
            class.id,
            "Homework via sync".to_string(),
            "Do the exercises".to_string(),
            100,
            true,
            false,
            None,
            None,
            due_at,
            0,
            Some(client_id),
            true,
            Some(1),
            Some("WW".to_string()),
        )
        .await
        .expect("create assignment");

    // Verify the assignment landed in the DB with the client-supplied ID
    assert_eq!(assignment.id, client_id);
    assert_eq!(assignment.class_id, class.id);
    assert_eq!(assignment.title, "Homework via sync");

    let found = AssignmentRepository::new(db)
        .find_by_id(client_id)
        .await
        .expect("find_by_id failed");
    assert!(found.is_some());
}

#[tokio::test]
async fn test_sync_create_class_lands_in_db() {
    let db = test_db().await;

    let client_id = Uuid::new_v4();
    let class = ClassRepository::new(db.clone())
        .create_class("Synced Class".to_string(), Some("Created via sync".to_string()), Some(client_id), false)
        .await
        .expect("create class");

    assert_eq!(class.id, client_id);
    assert_eq!(class.title, "Synced Class");

    let found = ClassRepository::new(db)
        .find_by_id(client_id)
        .await
        .expect("find failed");
    assert!(found.is_some());
}
