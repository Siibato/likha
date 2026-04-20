use chrono::Utc;
use uuid::Uuid;
use crate::db::repositories::assessment_repository::AssessmentRepository;
use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::submission_repository::SubmissionRepository;
use crate::tests::common::test_db::test_db;

async fn setup(db: &sea_orm::DatabaseConnection) -> (Uuid, Uuid, Uuid) {
    use crate::db::repositories::user_repository::UserRepository;
    let class_id = ClassRepository::new(db.clone())
        .create_class("Class".to_string(), None, None, false)
        .await
        .expect("class")
        .id;
    let now = Utc::now().naive_utc();
    let assessment_id = AssessmentRepository::new(db.clone())
        .create_assessment(class_id, "Quiz".to_string(), None, 30, now, now, false, 0, None, true, None, None, None)
        .await
        .expect("assessment")
        .id;
    let student_id = UserRepository::new(db.clone())
        .create_account("student_sub".to_string(), "Student Sub".to_string(), "student".to_string(), None)
        .await
        .expect("student")
        .id;
    (class_id, assessment_id, student_id)
}

#[tokio::test]
async fn test_create_and_find_submission() {
    let db = test_db().await;
    let (_, assessment_id, student_id) = setup(&db).await;
    let repo = SubmissionRepository::new(db);

    let sub = repo
        .create_submission(assessment_id, student_id, None)
        .await
        .expect("create_submission failed");

    assert_eq!(sub.assessment_id, assessment_id);
    assert_eq!(sub.user_id, student_id);

    let found = repo.find_by_id(sub.id).await.expect("find_by_id failed");
    assert!(found.is_some());
}

#[tokio::test]
async fn test_find_by_student_and_assessment() {
    let db = test_db().await;
    let (_, assessment_id, student_id) = setup(&db).await;
    let repo = SubmissionRepository::new(db);

    repo.create_submission(assessment_id, student_id, None)
        .await
        .expect("create failed");

    let found = repo
        .find_by_student_and_assessment(student_id, assessment_id)
        .await
        .expect("find failed");
    assert!(found.is_some());
}

#[tokio::test]
async fn test_count_by_assessment_id() {
    use crate::db::repositories::user_repository::UserRepository;
    let db = test_db().await;
    let (_, assessment_id, student1) = setup(&db).await;
    let student2 = UserRepository::new(db.clone())
        .create_account("student_sub2".to_string(), "S2".to_string(), "student".to_string(), None)
        .await
        .expect("s2").id;
    let repo = SubmissionRepository::new(db);

    assert_eq!(repo.count_by_assessment_id(assessment_id).await.expect("count failed"), 0);
    repo.create_submission(assessment_id, student1, None).await.expect("s1");
    repo.create_submission(assessment_id, student2, None).await.expect("s2");
    assert_eq!(repo.count_by_assessment_id(assessment_id).await.expect("count failed"), 2);
}
