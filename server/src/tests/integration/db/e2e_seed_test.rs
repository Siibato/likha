use sea_orm::EntityTrait;

use crate::seed::e2e::ids::*;
use crate::seed::e2e::seed_e2e_world;
use crate::tests::common::test_db::test_db;

#[tokio::test]
async fn test_e2e_seed_produces_expected_row_counts() {
    let db = test_db().await;
    seed_e2e_world(&db).await;

    // ── Users ──────────────────────────────────────────────────────────────────
    let users = ::entity::users::Entity::find()
        .all(&db).await.expect("find users");
    assert_eq!(users.len(), 7, "expected 7 users");

    // ── Classes ────────────────────────────────────────────────────────────────
    let classes = ::entity::classes::Entity::find()
        .all(&db).await.expect("find classes");
    assert_eq!(classes.len(), 5, "expected 5 classes (incl. deleted)");

    // ── TOS ────────────────────────────────────────────────────────────────────
    let tos = ::entity::table_of_specifications::Entity::find()
        .all(&db).await.expect("find TOS");
    assert_eq!(tos.len(), 2, "expected 2 TOS");

    // ── Competencies ───────────────────────────────────────────────────────────
    let comps = ::entity::tos_competencies::Entity::find()
        .all(&db).await.expect("find competencies");
    assert_eq!(comps.len(), 6, "expected 6 TOS competencies");

    // ── Assessments ────────────────────────────────────────────────────────────
    let assessments = ::entity::assessments::Entity::find()
        .all(&db).await.expect("find assessments");
    assert_eq!(assessments.len(), 5, "expected 5 assessments (incl. deleted)");

    // ── Assessment Questions ───────────────────────────────────────────────────
    let questions = ::entity::assessment_questions::Entity::find()
        .all(&db).await.expect("find questions");
    assert_eq!(questions.len(), 25, "expected 25 assessment questions (5 per assessment)");

    // ── Assignments ────────────────────────────────────────────────────────────
    let assignments = ::entity::assignments::Entity::find()
        .all(&db).await.expect("find assignments");
    assert_eq!(assignments.len(), 4, "expected 4 assignments (incl. deleted)");

    // ── Assessment Submissions ─────────────────────────────────────────────────
    let assess_subs = ::entity::assessment_submissions::Entity::find()
        .all(&db).await.expect("find assess subs");
    assert_eq!(assess_subs.len(), 5, "expected 5 assessment submissions");

    // ── Assignment Submissions ─────────────────────────────────────────────────
    let assign_subs = ::entity::assignment_submissions::Entity::find()
        .all(&db).await.expect("find assign subs");
    assert_eq!(assign_subs.len(), 3, "expected 3 assignment submissions");

    // ── Learning Materials ─────────────────────────────────────────────────────
    let mats = ::entity::learning_materials::Entity::find()
        .all(&db).await.expect("find materials");
    assert_eq!(mats.len(), 4, "expected 4 learning materials");

    // ── Grade Records ──────────────────────────────────────────────────────────
    let grade_records = ::entity::grade_record::Entity::find()
        .all(&db).await.expect("find grade records");
    // setup_defaults creates 4 periods × 2 classes = 8 records
    assert_eq!(grade_records.len(), 8, "expected 8 grade records");

    // ── School Settings ────────────────────────────────────────────────────────
    let settings = ::entity::school_settings::Entity::find()
        .all(&db).await.expect("find school_settings");
    assert_eq!(settings.len(), 1, "expected 1 school_settings row");

    // ── Hardcoded UUID spot checks ─────────────────────────────────────────────
    let admin = ::entity::users::Entity::find_by_id(ADMIN_ID)
        .one(&db).await.expect("find admin").expect("admin must exist");
    assert_eq!(admin.username, "admin");
    assert_eq!(admin.role, "admin");

    let t1 = ::entity::users::Entity::find_by_id(TEACHER_01_ID)
        .one(&db).await.expect("find teacher_01").expect("teacher_01 must exist");
    assert_eq!(t1.username, "teacher_01");
    assert_eq!(t1.account_status, "active");

    let math_class = ::entity::classes::Entity::find_by_id(CLASS_MATH_8A_ID)
        .one(&db).await.expect("find math class").expect("math class must exist");
    assert_eq!(math_class.title, "Mathematics 8A");
    assert_eq!(math_class.grade_level.as_deref(), Some("8"));

    let assess = ::entity::assessments::Entity::find_by_id(ASSESS_MATH_QUIZ1_ID)
        .one(&db).await.expect("find quiz1").expect("quiz1 must exist");
    assert!(assess.is_published, "Math Quiz 1 must be published");
    assert!(assess.results_released, "Math Quiz 1 must have results released");

    let quiz2 = ::entity::assessments::Entity::find_by_id(ASSESS_MATH_QUIZ2_ID)
        .one(&db).await.expect("find quiz2").expect("quiz2 must exist");
    assert!(quiz2.is_published, "Math Quiz 2 must be published");
    assert!(!quiz2.results_released, "Math Quiz 2 results must NOT be released");

    let deleted_student = ::entity::users::Entity::find_by_id(STUDENT_DELETED_ID)
        .one(&db).await.expect("find deleted student").expect("deleted student must exist");
    assert!(deleted_student.deleted_at.is_some(), "student_deleted_99 must have deleted_at set");
}

#[tokio::test]
async fn test_e2e_seed_soft_deleted_entities_have_deleted_at() {
    let db = test_db().await;
    seed_e2e_world(&db).await;

    let deleted_class = ::entity::classes::Entity::find_by_id(CLASS_DELETED_8_ID)
        .one(&db).await.expect("find deleted class").expect("deleted class must exist");
    assert!(deleted_class.deleted_at.is_some(), "deleted class must have deleted_at");

    let deleted_assess = ::entity::assessments::Entity::find_by_id(ASSESS_DELETED_MATH_ID)
        .one(&db).await.expect("find deleted assess").expect("deleted assess must exist");
    assert!(deleted_assess.deleted_at.is_some(), "deleted assessment must have deleted_at");

    let deleted_assign = ::entity::assignments::Entity::find_by_id(ASSIGN_DELETED_ID)
        .one(&db).await.expect("find deleted assign").expect("deleted assign must exist");
    assert!(deleted_assign.deleted_at.is_some(), "deleted assignment must have deleted_at");
}

#[tokio::test]
async fn test_e2e_seed_grade_items_created_for_published_entities() {
    let db = test_db().await;
    seed_e2e_world(&db).await;

    let grade_items = ::entity::grade_items::Entity::find()
        .all(&db).await.expect("find grade items");

    // 4 published assessments + 3 published assignments = 7 grade items minimum
    assert!(grade_items.len() >= 7, "expected at least 7 grade items, got {}", grade_items.len());
}
