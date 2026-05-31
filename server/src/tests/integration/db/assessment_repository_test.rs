use chrono::Utc;
use crate::db::repositories::assessment_repository::AssessmentRepository;
use crate::db::repositories::class_repository::ClassRepository;
use crate::tests::common::test_db::test_db;

async fn create_test_class(db: &sea_orm::DatabaseConnection) -> uuid::Uuid {
    ClassRepository::new(db.clone())
        .create_class("Class".to_string(), None, None, false)
        .await
        .expect("create_class failed")
        .id
}

#[tokio::test]
async fn test_create_and_find_assessment() {
    let db = test_db().await;
    let class_id = create_test_class(&db).await;
    let repo = AssessmentRepository::new(db);

    let now = Utc::now().naive_utc();
    let assessment = repo
        .create_assessment(
            class_id,
            "Quiz 1".to_string(),
            None,
            30,
            now,
            now,
            false,
            0,
            None,
            true,
            Some(1),
            None,
            None,
        )
        .await
        .expect("create_assessment failed");

    assert_eq!(assessment.title, "Quiz 1");
    assert_eq!(assessment.class_id, class_id);

    let found = repo.find_by_id(assessment.id).await.expect("find_by_id failed");
    assert!(found.is_some());
}

#[tokio::test]
async fn test_find_by_class_id() {
    let db = test_db().await;
    let class_id = create_test_class(&db).await;
    let repo = AssessmentRepository::new(db);
    let now = Utc::now().naive_utc();

    repo.create_assessment(class_id, "A1".to_string(), None, 60, now, now, false, 0, None, true, None, None, None)
        .await
        .expect("create failed");

    let list = repo.find_by_class_id(class_id).await.expect("find failed");
    assert_eq!(list.len(), 1);
}

#[tokio::test]
async fn test_find_by_id_returns_none_for_unknown() {
    let db = test_db().await;
    let repo = AssessmentRepository::new(db);
    let found = repo.find_by_id(uuid::Uuid::new_v4()).await.expect("find failed");
    assert!(found.is_none());
}
