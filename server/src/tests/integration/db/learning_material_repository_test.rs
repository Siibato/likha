use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::learning_material_repository::LearningMaterialRepository;
use crate::tests::common::test_db::test_db;

#[tokio::test]
async fn test_create_and_find_material() {
    let db = test_db().await;
    let class_id = ClassRepository::new(db.clone())
        .create_class("LM Class".to_string(), None, None, false)
        .await
        .expect("class")
        .id;
    let repo = LearningMaterialRepository::new(db);

    let material = repo
        .create_material(
            class_id,
            "Lesson 1".to_string(),
            Some("Intro".to_string()),
            Some("Body text".to_string()),
            0,
            None,
        )
        .await
        .expect("create failed");

    assert_eq!(material.title, "Lesson 1");
    assert_eq!(material.class_id, class_id);

    let found = repo.find_by_id(material.id).await.expect("find_by_id failed");
    assert!(found.is_some());
}

#[tokio::test]
async fn test_find_by_class_id() {
    let db = test_db().await;
    let class_id = ClassRepository::new(db.clone())
        .create_class("LM Class2".to_string(), None, None, false)
        .await
        .expect("class")
        .id;
    let repo = LearningMaterialRepository::new(db);

    repo.create_material(class_id, "M1".to_string(), None, None, 0, None).await.expect("m1");
    repo.create_material(class_id, "M2".to_string(), None, None, 1, None).await.expect("m2");

    let list = repo.find_by_class_id(class_id).await.expect("find failed");
    assert_eq!(list.len(), 2);
    assert_eq!(list[0].title, "M1");
}

#[tokio::test]
async fn test_find_by_class_id_returns_empty() {
    let db = test_db().await;
    let repo = LearningMaterialRepository::new(db);
    let list = repo.find_by_class_id(uuid::Uuid::new_v4()).await.expect("find failed");
    assert!(list.is_empty());
}
