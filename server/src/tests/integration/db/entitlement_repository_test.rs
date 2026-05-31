use uuid::Uuid;
use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::entitlement_repository::EntitlementRepository;
use crate::db::repositories::user_repository::UserRepository;
use crate::tests::common::test_db::test_db;

#[tokio::test]
async fn test_get_accessible_classes_returns_empty_for_new_user() {
    let db = test_db().await;
    let user = UserRepository::new(db.clone())
        .create_account("newuser".to_string(), "New".to_string(), "teacher".to_string(), None)
        .await
        .expect("user");
    let repo = EntitlementRepository::new(db);

    let classes = repo
        .get_user_accessible_classes(user.id, "teacher")
        .await
        .expect("entitlement failed");
    assert!(classes.is_empty());
}

#[tokio::test]
async fn test_get_accessible_classes_admin_sees_all() {
    let db = test_db().await;
    ClassRepository::new(db.clone())
        .create_class("C1".to_string(), None, None, false)
        .await
        .expect("class1");
    ClassRepository::new(db.clone())
        .create_class("C2".to_string(), None, None, false)
        .await
        .expect("class2");

    let repo = EntitlementRepository::new(db);
    let classes = repo
        .get_user_accessible_classes(Uuid::new_v4(), "admin")
        .await
        .expect("entitlement failed");
    assert_eq!(classes.len(), 2);
}

#[tokio::test]
async fn test_is_teacher_of_class_returns_false_when_not_participant() {
    let db = test_db().await;
    let repo = EntitlementRepository::new(db);
    let result = repo
        .is_teacher_of_class(Uuid::new_v4(), Uuid::new_v4())
        .await
        .expect("failed");
    assert!(!result);
}

#[tokio::test]
async fn test_invalid_role_returns_error() {
    let db = test_db().await;
    let repo = EntitlementRepository::new(db);
    let result = repo
        .get_user_accessible_classes(Uuid::new_v4(), "superuser")
        .await;
    assert!(result.is_err());
}
