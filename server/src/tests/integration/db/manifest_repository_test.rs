use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::manifest_repository::ManifestRepository;
use crate::tests::common::test_db::test_db;

#[tokio::test]
async fn test_get_classes_manifest_empty_when_no_classes() {
    let db = test_db().await;
    let repo = ManifestRepository::new(db);
    let manifest = repo.get_classes_manifest(vec![]).await.expect("manifest failed");
    assert!(manifest.is_empty());
}

#[tokio::test]
async fn test_get_classes_manifest_returns_entries() {
    let db = test_db().await;
    let class_id = ClassRepository::new(db.clone())
        .create_class("Manifest Class".to_string(), None, None, false)
        .await
        .expect("class")
        .id;
    let repo = ManifestRepository::new(db);

    let manifest = repo.get_classes_manifest(vec![class_id]).await.expect("manifest failed");
    assert_eq!(manifest.len(), 1);
    assert_eq!(manifest[0].id, class_id);
    assert!(!manifest[0].deleted);
}

#[tokio::test]
async fn test_get_classes_manifest_with_unknown_ids() {
    let db = test_db().await;
    let repo = ManifestRepository::new(db);
    let manifest = repo
        .get_classes_manifest(vec![uuid::Uuid::new_v4()])
        .await
        .expect("manifest failed");
    assert!(manifest.is_empty());
}
