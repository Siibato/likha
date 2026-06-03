use chrono::Duration;
use sea_orm::{ActiveModelTrait, ConnectionTrait, DatabaseConnection, EntityTrait, QueryFilter, ColumnTrait, Set};
use uuid::Uuid;

use ::entity::{
    answer_key_acceptable_answers, answer_keys, assessment_questions,
    assessment_submissions, assignments, classes,
    grade_scores, learning_materials, period_grades, school_settings, users,
};

use crate::modules::assessment::repository::AssessmentRepository;
use crate::modules::assessment::service::AssessmentService;
use crate::modules::assignment::repository::AssignmentRepository;
use crate::modules::assignment::service::AssignmentService;
use crate::modules::auth::UserRepository;
use crate::modules::class::repository::ClassRepository;
use crate::modules::grading::repository::GradeComputationRepository;
use crate::modules::tos::repository::TosRepository;

use super::data::*;

pub async fn seed_e2e_world(db: &DatabaseConnection) {
    // Disable FK enforcement during seeding. The production DB connection does not
    // enable FKs (db.rs never executes PRAGMA foreign_keys = ON), but the test DB
    // migrator leaves FKs ON. Raw-SQL helpers like upsert_score pass UUIDs as TEXT
    // strings while SeaORM stores them as BLOB, causing spurious FK violations.
    db.execute(sea_orm::Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "PRAGMA foreign_keys = OFF".to_string(),
    )).await.expect("seed: disable FK");

    step0_school_settings(db).await;
    step1_users(db).await;
    step2_classes(db).await;
    step3_tos(db).await;
    step4_assessments(db).await;
    step5_assignments(db).await;
    step6_submissions(db).await;
    step7_materials(db).await;
    step8_grading(db).await;
    // Re-enable FK enforcement now that seeding is done.
    db.execute(sea_orm::Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "PRAGMA foreign_keys = ON".to_string(),
    )).await.expect("seed: re-enable FK");

    println!("✅ E2E seed complete.");
}

// ─── Step 0: School Settings ─────────────────────────────────────────────────

async fn step0_school_settings(db: &DatabaseConnection) {
    let n = now();
    let model = school_settings::ActiveModel {
        id: Set(1),
        school_code: Set("E2E-TEST".to_string()),
        school_name: Set(Some("Likha E2E Test School".to_string())),
        school_region: Set(Some("NCR".to_string())),
        school_division: Set(Some("Division of City Schools".to_string())),
        school_year: Set(Some("2025-2026".to_string())),
        updated_at: Set(n),
    };
    model.insert(db).await.expect("seed: school_settings");
    println!("  [seed] school_settings done");
}

// ─── Step 1: Users ───────────────────────────────────────────────────────────

async fn step1_users(db: &DatabaseConnection) {
    let n = now();
    let created = days_ago(30);
    let activated = days_ago(29);
    let deleted = days_ago(6);

    let user_repo = UserRepository::new(db.clone());

    // Remove any default admin inserted by reset-db so we can insert with hardcoded UUID.
    users::Entity::delete_many()
        .filter(users::Column::Role.eq("admin"))
        .exec(db)
        .await
        .expect("seed: delete default admin");

    struct UserSpec {
        id: Uuid,
        username: &'static str,
        full_name: &'static str,
        role: &'static str,
        password: Option<&'static str>,
        account_status: &'static str,
        deleted: bool,
    }

    let specs = vec![
        UserSpec { id: ADMIN_ID, username: "admin", full_name: "System Administrator", role: "admin", password: None, account_status: "pending_activation", deleted: false },
        UserSpec { id: TEACHER_01_ID, username: "teacher_01", full_name: "Teacher One", role: "teacher", password: Some(PASSWORD_TEACHER), account_status: "active", deleted: false },
        UserSpec { id: TEACHER_02_ID, username: "teacher_02", full_name: "Teacher Two", role: "teacher", password: Some(PASSWORD_TEACHER), account_status: "active", deleted: false },
        UserSpec { id: STUDENT_01_ID, username: "student_01", full_name: "Student One", role: "student", password: Some(PASSWORD_STUDENT), account_status: "active", deleted: false },
        UserSpec { id: STUDENT_02_ID, username: "student_02", full_name: "Student Two", role: "student", password: Some(PASSWORD_STUDENT), account_status: "active", deleted: false },
        UserSpec { id: STUDENT_03_ID, username: "student_03", full_name: "Student Three", role: "student", password: Some(PASSWORD_STUDENT), account_status: "active", deleted: false },
        UserSpec { id: STUDENT_DELETED_ID, username: "student_deleted_99", full_name: "Student Deleted 99", role: "student", password: Some(PASSWORD_STUDENT), account_status: "active", deleted: true },
    ];

    for spec in specs {
        user_repo
            .create_account(spec.username.to_string(), spec.full_name.to_string(), spec.role.to_string(), Some(spec.id))
            .await
            .expect("seed: create_account");

        if let Some(pw) = spec.password {
            let hash = bcrypt::hash(pw, 4).expect("seed: bcrypt");
            user_repo
                .set_password(spec.id, hash)
                .await
                .expect("seed: set_password");
        }

        // Activate + patch timestamps
        let user = users::Entity::find_by_id(spec.id)
            .one(db)
            .await
            .expect("seed: find user")
            .unwrap();
        let mut am: users::ActiveModel = user.into();
        am.created_at = Set(created);
        am.updated_at = Set(created);
        if spec.account_status == "active" {
            am.account_status = Set("active".to_string());
            am.activated_at = Set(Some(activated));
        }
        if spec.deleted {
            am.deleted_at = Set(Some(deleted));
        }
        am.update(db).await.expect("seed: patch user timestamps");
    }

    println!("  [seed] users done");
    let _ = n; // suppress unused warning
}

// ─── Step 2: Classes & Enrollment ────────────────────────────────────────────

async fn step2_classes(db: &DatabaseConnection) {
    let created = days_ago(25);

    let class_repo = ClassRepository::new(db.clone());

    struct ClassSpec {
        id: Uuid,
        title: &'static str,
        grade_level: &'static str,
        is_advisory: bool,
        is_archived: bool,
        deleted: bool,
    }

    let specs = vec![
        ClassSpec { id: CLASS_MATH_8A_ID, title: "Mathematics 8A", grade_level: "8", is_advisory: false, is_archived: false, deleted: false },
        ClassSpec { id: CLASS_SCI_8A_ID, title: "Science 8A", grade_level: "8", is_advisory: false, is_archived: false, deleted: false },
        ClassSpec { id: CLASS_ADVISORY_8A_ID, title: "Advisory 8A", grade_level: "8", is_advisory: true, is_archived: false, deleted: false },
        ClassSpec { id: CLASS_ARCHIVED_10A_ID, title: "Archived Class 10A", grade_level: "10", is_advisory: false, is_archived: true, deleted: false },
        ClassSpec { id: CLASS_DELETED_8_ID, title: "Deleted Science 8 (should not appear)", grade_level: "8", is_advisory: false, is_archived: false, deleted: true },
    ];

    for spec in specs {
        class_repo
            .create_class(spec.title.to_string(), Some("E2E test class".to_string()), Some(spec.id), spec.is_advisory)
            .await
            .expect("seed: create_class");

        let cls = classes::Entity::find_by_id(spec.id)
            .one(db).await.expect("seed: find class").unwrap();
        let mut am: classes::ActiveModel = cls.into();
        am.grade_level = Set(Some(spec.grade_level.to_string()));
        am.school_year = Set(Some("2025-2026".to_string()));
        am.is_archived = Set(spec.is_archived);
        am.created_at = Set(created);
        am.updated_at = Set(created);
        if spec.deleted {
            am.deleted_at = Set(Some(days_ago(5)));
        }
        am.update(db).await.expect("seed: patch class");
    }

    // Enroll teachers
    // teacher_01 → Math 8A, Sci 8A, Advisory 8A
    for cid in [CLASS_MATH_8A_ID, CLASS_SCI_8A_ID, CLASS_ADVISORY_8A_ID] {
        class_repo.add_participant(cid, TEACHER_01_ID).await.expect("seed: add teacher_01");
    }
    // teacher_02 → Advisory 8A, Archived 10A
    for cid in [CLASS_ADVISORY_8A_ID, CLASS_ARCHIVED_10A_ID] {
        class_repo.add_participant(cid, TEACHER_02_ID).await.expect("seed: add teacher_02");
    }

    // Enroll students
    // student_01 → Math, Sci, Advisory
    for cid in [CLASS_MATH_8A_ID, CLASS_SCI_8A_ID, CLASS_ADVISORY_8A_ID] {
        class_repo.add_participant(cid, STUDENT_01_ID).await.expect("seed: add student_01");
    }
    // student_02 → Math, Sci, Advisory
    for cid in [CLASS_MATH_8A_ID, CLASS_SCI_8A_ID, CLASS_ADVISORY_8A_ID] {
        class_repo.add_participant(cid, STUDENT_02_ID).await.expect("seed: add student_02");
    }
    // student_03 → Math, Advisory
    for cid in [CLASS_MATH_8A_ID, CLASS_ADVISORY_8A_ID] {
        class_repo.add_participant(cid, STUDENT_03_ID).await.expect("seed: add student_03");
    }

    println!("  [seed] classes & enrollment done");
}

// ─── Step 3: TOS & Competencies ──────────────────────────────────────────────

async fn step3_tos(db: &DatabaseConnection) {
    let tos_repo = TosRepository::new(db.clone());

    tos_repo.create_tos(
        TOS_MATH_8A_ID, CLASS_MATH_8A_ID, 1,
        "TOS for Mathematics 8A - Q1", "difficulty", 30, "days",
        30.0, 50.0, 20.0, 15.0, 20.0, 20.0, 15.0, 15.0, 15.0,
    ).await.expect("seed: TOS math");

    tos_repo.create_tos(
        TOS_SCI_8A_ID, CLASS_SCI_8A_ID, 1,
        "TOS for Science 8A - Q1", "bloom", 30, "days",
        30.0, 50.0, 20.0, 15.0, 20.0, 20.0, 15.0, 15.0, 15.0,
    ).await.expect("seed: TOS sci");

    struct CompSpec {
        id: Uuid,
        tos_id: Uuid,
        code: &'static str,
        text: &'static str,
        order: i32,
    }

    let comps = vec![
        CompSpec { id: COMP_MATH_1_ID, tos_id: TOS_MATH_8A_ID, code: "M8NS-Ia-1", text: "Represents integers on number line", order: 0 },
        CompSpec { id: COMP_MATH_2_ID, tos_id: TOS_MATH_8A_ID, code: "M8NS-Ib-2", text: "Performs operations on integers", order: 1 },
        CompSpec { id: COMP_MATH_3_ID, tos_id: TOS_MATH_8A_ID, code: "M8AL-Ia-1", text: "Translates verbal phrases to mathematical expressions", order: 2 },
        CompSpec { id: COMP_SCI_1_ID, tos_id: TOS_SCI_8A_ID, code: "S8MT-Ia-1", text: "Describes the distribution of active volcanoes", order: 0 },
        CompSpec { id: COMP_SCI_2_ID, tos_id: TOS_SCI_8A_ID, code: "S8MT-Ib-2", text: "Explains how energy from volcanoes may be tapped", order: 1 },
        CompSpec { id: COMP_SCI_3_ID, tos_id: TOS_SCI_8A_ID, code: "S8ES-Ia-1", text: "Describes the different layers of the Earth", order: 2 },
    ];

    for c in comps {
        tos_repo.create_competency(
            c.id, c.tos_id, Some(c.code), c.text,
            5, c.order,
            None, None, None, None, None, None, None, None, None,
        ).await.expect("seed: competency");
    }

    println!("  [seed] TOS done");
}

// ─── Step 4: Assessments, Questions, Choices, Answer Keys, Publish ───────────

async fn step4_assessments(db: &DatabaseConnection) {
    let assessment_repo = AssessmentRepository::new(db.clone());
    let assessment_service = AssessmentService::new(db.clone());
    let created = days_ago(15);

    struct AssessSpec {
        id: Uuid,
        class_id: Uuid,
        title: &'static str,
        open_offset: i64,
        close_offset: i64,
        show_results: bool,
        results_released: bool,
        component: &'static str,
        tos_id: Uuid,
        questions: QuestionSet,
        deleted: bool,
    }

    let specs = vec![
        AssessSpec {
            id: ASSESS_MATH_QUIZ1_ID,
            class_id: CLASS_MATH_8A_ID,
            title: "Math Quiz 1 (Closed)",
            open_offset: -7,
            close_offset: -1,
            show_results: true,
            results_released: true,
            component: "written_work",
            tos_id: TOS_MATH_8A_ID,
            questions: math_q1_questions(),
            deleted: false,
        },
        AssessSpec {
            id: ASSESS_MATH_QUIZ2_ID,
            class_id: CLASS_MATH_8A_ID,
            title: "Math Quiz 2 (Open)",
            open_offset: -1,
            close_offset: 7,
            show_results: false,
            results_released: false,
            component: "performance_task",
            tos_id: TOS_MATH_8A_ID,
            questions: math_q2_questions(),
            deleted: false,
        },
        AssessSpec {
            id: ASSESS_SCI_TEST1_ID,
            class_id: CLASS_SCI_8A_ID,
            title: "Science Test 1 (Closed)",
            open_offset: -10,
            close_offset: -2,
            show_results: true,
            results_released: true,
            component: "quarterly_assessment",
            tos_id: TOS_SCI_8A_ID,
            questions: sci_t1_questions(),
            deleted: false,
        },
        AssessSpec {
            id: ASSESS_SCI_TEST2_ID,
            class_id: CLASS_SCI_8A_ID,
            title: "Science Test 2 (Open)",
            open_offset: 1,
            close_offset: 14,
            show_results: false,
            results_released: false,
            component: "written_work",
            tos_id: TOS_SCI_8A_ID,
            questions: sci_t2_questions(),
            deleted: false,
        },
        AssessSpec {
            id: ASSESS_DELETED_MATH_ID,
            class_id: CLASS_MATH_8A_ID,
            title: "[DELETED] Review Test - Math 8A",
            open_offset: -8,
            close_offset: -4,
            show_results: false,
            results_released: false,
            component: "written_work",
            tos_id: TOS_MATH_8A_ID,
            questions: deleted_questions(),
            deleted: true,
        },
    ];

    let n = now();
    for spec in specs {
        let open_at = n + Duration::days(spec.open_offset);
        let close_at = n + Duration::days(spec.close_offset);

        assessment_repo.create_assessment(
            spec.class_id,
            spec.title.to_string(),
            None,
            30,
            open_at,
            close_at,
            spec.show_results,
            0,
            Some(spec.id),
            false,
            Some(1),
            Some(spec.component.to_string()),
            Some(spec.tos_id.to_string()),
        ).await.expect("seed: create_assessment");

        // Patch creation time
        let a = ::entity::assessments::Entity::find_by_id(spec.id)
            .one(db).await.expect("seed: find assess").unwrap();
        let mut am: ::entity::assessments::ActiveModel = a.into();
        am.created_at = Set(created);
        am.updated_at = Set(created);
        am.update(db).await.expect("seed: patch assess");

        // Add 5 questions
        let qs = [
            (spec.questions.q1, "multiple_choice", "What is the first concept in this topic?", 1, 0, spec.questions.comps[0], "easy", "remembering"),
            (spec.questions.q2, "multiple_choice", "Which statement best describes the second concept?", 2, 1, spec.questions.comps[1], "medium", "understanding"),
            (spec.questions.q3, "identification", "Name the key term for the third concept.", 1, 2, spec.questions.comps[0], "easy", "applying"),
            (spec.questions.q4, "identification", "Identify the principle used in the fourth concept.", 2, 3, spec.questions.comps[1], "medium", "analyzing"),
            (spec.questions.q5, "essay", "Explain the fifth concept in your own words.", 5, 4, spec.questions.comps[2], "hard", "evaluating"),
        ];

        for (qid, qtype, qtext, points, order, comp_id, difficulty, cog_level) in qs {
            assessment_repo.add_question(
                spec.id,
                qtype.to_string(),
                qtext.to_string(),
                points,
                order,
                false,
                Some(qid),
            ).await.expect("seed: add_question");

            // Patch tos_competency_id, difficulty, cognitive_level
            let q = assessment_questions::Entity::find_by_id(qid)
                .one(db).await.expect("seed: find q").unwrap();
            let mut qam: assessment_questions::ActiveModel = q.into();
            qam.tos_competency_id = Set(Some(comp_id.to_string()));
            qam.difficulty = Set(Some(difficulty.to_string()));
            qam.cognitive_level = Set(Some(cog_level.to_string()));
            qam.update(db).await.expect("seed: patch question");
        }

        // Choices for MCQ questions (q1, q2)
        for (qid, correct_idx) in [(spec.questions.q1, 1usize), (spec.questions.q2, 2usize)] {
            let choices_texts = ["Option A", "Option B (correct)", "Option C", "Option D"];
            for (i, text) in choices_texts.iter().enumerate() {
                assessment_repo.add_choice(
                    qid,
                    text.to_string(),
                    i == correct_idx,
                    i as i32,
                ).await.expect("seed: add_choice");
            }
        }

        // Answer keys for identification questions (q3, q4)
        for (qid, answer_text) in [(spec.questions.q3, "42"), (spec.questions.q4, "principle")] {
            let ak = answer_keys::ActiveModel {
                id: Set(Uuid::new_v4()),
                question_id: Set(qid),
            };
            let inserted_ak = ak.insert(db).await.expect("seed: answer_key");

            // Primary acceptable answer
            let acc1 = answer_key_acceptable_answers::ActiveModel {
                id: Set(Uuid::new_v4()),
                answer_key_id: Set(inserted_ak.id),
                answer_text: Set(answer_text.to_string()),
            };
            acc1.insert(db).await.expect("seed: acceptable_answer 1");

            // Variant acceptable answer
            let variant = format!("{}-variant", answer_text);
            let acc2 = answer_key_acceptable_answers::ActiveModel {
                id: Set(Uuid::new_v4()),
                answer_key_id: Set(inserted_ak.id),
                answer_text: Set(variant),
            };
            acc2.insert(db).await.expect("seed: acceptable_answer 2");
        }

        // Answer key for essay question (q5) — empty text, manual grading
        let essay_ak = answer_keys::ActiveModel {
            id: Set(Uuid::new_v4()),
            question_id: Set(spec.questions.q5),
        };
        essay_ak.insert(db).await.expect("seed: essay answer_key");

        // Publish via service (needs at least 1 question, auto-creates grade item)
        if !spec.deleted {
            assessment_service
                .publish_assessment(spec.id, TEACHER_01_ID)
                .await
                .expect("seed: publish_assessment");

            if spec.results_released {
                assessment_repo
                    .release_results(spec.id)
                    .await
                    .expect("seed: release_results");
            }
        } else {
            // Soft-delete the assessment
            let a2 = ::entity::assessments::Entity::find_by_id(spec.id)
                .one(db).await.expect("seed: find assess for delete").unwrap();
            let mut am2: ::entity::assessments::ActiveModel = a2.into();
            am2.deleted_at = Set(Some(days_ago(4)));
            am2.update(db).await.expect("seed: soft delete assess");
        }
    }

    println!("  [seed] assessments done");
}

// ─── Step 5: Assignments ─────────────────────────────────────────────────────

async fn step5_assignments(db: &DatabaseConnection) {
    let assignment_repo = AssignmentRepository::new(db.clone());
    let assignment_service = AssignmentService::new(db.clone());
    let created = days_ago(15);

    struct AssignSpec {
        id: Uuid,
        class_id: Uuid,
        title: &'static str,
        due_offset: i64,
        total_points: i32,
        component: &'static str,
        deleted: bool,
    }

    let specs = vec![
        AssignSpec { id: ASSIGN_MATH_HW1_ID, class_id: CLASS_MATH_8A_ID, title: "Math Homework 1 (Past Due)", due_offset: -5, total_points: 50, component: "written_work", deleted: false },
        AssignSpec { id: ASSIGN_SCI_LAB_ID, class_id: CLASS_SCI_8A_ID, title: "Science Lab Report (Due Soon)", due_offset: 2, total_points: 100, component: "performance_task", deleted: false },
        AssignSpec { id: ASSIGN_MATH_PROJECT_ID, class_id: CLASS_MATH_8A_ID, title: "Math Project (Future)", due_offset: 14, total_points: 200, component: "performance_task", deleted: false },
        AssignSpec { id: ASSIGN_DELETED_ID, class_id: CLASS_SCI_8A_ID, title: "[DELETED] Extra Credit", due_offset: -3, total_points: 50, component: "written_work", deleted: true },
    ];

    let n = now();
    for spec in specs {
        let due_at = n + Duration::days(spec.due_offset);

        assignment_repo.create_assignment(
            spec.class_id,
            spec.title.to_string(),
            "Complete the assignment as instructed.".to_string(),
            spec.total_points,
            true,
            false,
            None,
            None,
            due_at,
            0,
            Some(spec.id),
            false,
            Some(1),
            Some(spec.component.to_string()),
        ).await.expect("seed: create_assignment");

        // Patch creation time
        let a = assignments::Entity::find_by_id(spec.id)
            .one(db).await.expect("seed: find assignment").unwrap();
        let mut am: ::entity::assignments::ActiveModel = a.into();
        am.created_at = Set(created);
        am.updated_at = Set(created);
        am.update(db).await.expect("seed: patch assignment");

        if spec.deleted {
            let a2 = assignments::Entity::find_by_id(spec.id)
                .one(db).await.expect("seed: find assignment del").unwrap();
            let mut am2: ::entity::assignments::ActiveModel = a2.into();
            am2.deleted_at = Set(Some(days_ago(3)));
            am2.update(db).await.expect("seed: soft delete assignment");
        } else {
            // Publish via service (auto-creates grade item)
            assignment_service
                .publish_assignment(spec.id, TEACHER_01_ID)
                .await
                .expect("seed: publish_assignment");
        }
    }

    println!("  [seed] assignments done");
}

// ─── Step 6: Submissions ─────────────────────────────────────────────────────

async fn step6_submissions(db: &DatabaseConnection) {
    step6a_assessment_submissions(db).await;
    step6b_assignment_submissions(db).await;
    println!("  [seed] submissions done");
}

async fn step6a_assessment_submissions(db: &DatabaseConnection) {
    let assessment_repo = AssessmentRepository::new(db.clone());

    struct SubSpec {
        sub_id: Uuid,
        assessment_id: Uuid,
        student_id: Uuid,
        started_offset: i64,
    }

    let specs = vec![
        SubSpec { sub_id: SUB_ASSESS_S01_MQ1, assessment_id: ASSESS_MATH_QUIZ1_ID, student_id: STUDENT_01_ID, started_offset: -6 },
        SubSpec { sub_id: SUB_ASSESS_S02_MQ1, assessment_id: ASSESS_MATH_QUIZ1_ID, student_id: STUDENT_02_ID, started_offset: -6 },
        SubSpec { sub_id: SUB_ASSESS_S03_MQ1, assessment_id: ASSESS_MATH_QUIZ1_ID, student_id: STUDENT_03_ID, started_offset: -5 },
        SubSpec { sub_id: SUB_ASSESS_S01_ST1, assessment_id: ASSESS_SCI_TEST1_ID, student_id: STUDENT_01_ID, started_offset: -9 },
        SubSpec { sub_id: SUB_ASSESS_S02_ST1, assessment_id: ASSESS_SCI_TEST1_ID, student_id: STUDENT_02_ID, started_offset: -9 },
    ];

    let questions_map: Vec<(Uuid, &[Uuid])> = vec![
        (ASSESS_MATH_QUIZ1_ID, &[Q_MATH_Q1_1, Q_MATH_Q1_2, Q_MATH_Q1_3, Q_MATH_Q1_4, Q_MATH_Q1_5]),
        (ASSESS_SCI_TEST1_ID, &[Q_SCI_T1_1, Q_SCI_T1_2, Q_SCI_T1_3, Q_SCI_T1_4, Q_SCI_T1_5]),
    ];

    for spec in &specs {
        assessment_repo
            .create_submission(spec.assessment_id, spec.student_id, Some(spec.sub_id))
            .await
            .expect("seed: create_submission");

        // Patch started_at and submitted_at
        let started = days_ago(spec.started_offset as u64);
        let submitted = started + Duration::minutes(30);
        let sub = assessment_submissions::Entity::find_by_id(spec.sub_id)
            .one(db).await.expect("seed: find assess sub").unwrap();
        let mut sam: assessment_submissions::ActiveModel = sub.into();
        sam.started_at = Set(started);
        sam.submitted_at = Set(Some(submitted));
        sam.update(db).await.expect("seed: patch assess sub timestamps");

        // Upsert answers
        let question_ids = questions_map
            .iter()
            .find(|(aid, _)| *aid == spec.assessment_id)
            .map(|(_, qs)| *qs)
            .unwrap_or(&[]);

        // Get the correct choice id for MCQ questions (index 1 → "Option B (correct)")
        for (i, &qid) in question_ids.iter().enumerate() {
            let answer = assessment_repo
                .upsert_answer(spec.sub_id, qid, None)
                .await
                .expect("seed: upsert_answer");

            match i {
                0 | 1 => {
                    // MCQ: find the correct choice
                    let choices = assessment_repo
                        .find_choices_by_question_id(qid)
                        .await
                        .expect("seed: find_choices");
                    let correct = choices.iter().find(|c| c.is_correct).cloned();

                    // student_01 always correct; student_02 correct on q1 only; student_03 always wrong
                    let chosen = if spec.student_id == STUDENT_01_ID {
                        correct.clone()
                    } else if spec.student_id == STUDENT_02_ID && i == 0 {
                        correct.clone()
                    } else {
                        choices.iter().find(|c| !c.is_correct).cloned()
                    };

                    if let Some(c) = chosen {
                        assessment_repo
                            .save_answer_choices(answer.id, vec![c.id])
                            .await
                            .expect("seed: save_answer_choices");
                        let is_correct = c.is_correct;
                        let pts = if is_correct { if i == 0 { 1.0 } else { 2.0 } } else { 0.0 };
                        assessment_repo
                            .update_answer_grade(answer.id, Some(is_correct), pts)
                            .await
                            .expect("seed: update_answer_grade MCQ");
                    }
                }
                2 | 3 => {
                    // Identification: give the correct text answer for student_01; empty for others
                    let text = if spec.student_id == STUDENT_01_ID {
                        if i == 2 { "42".to_string() } else { "principle".to_string() }
                    } else {
                        "wrong answer".to_string()
                    };
                    assessment_repo
                        .save_answer_text(answer.id, text.clone())
                        .await
                        .expect("seed: save_answer_text");
                    let is_correct = spec.student_id == STUDENT_01_ID;
                    let pts = if is_correct { if i == 2 { 1.0 } else { 2.0 } } else { 0.0 };
                    assessment_repo
                        .update_answer_grade(answer.id, Some(is_correct), pts)
                        .await
                        .expect("seed: update_answer_grade ident");
                }
                4 => {
                    // Essay: no answer text, points = 0 (ungraded)
                }
                _ => {}
            }
        }

        // Calculate total points and mark submitted
        let total: f64 = if spec.student_id == STUDENT_01_ID {
            1.0 + 2.0 + 1.0 + 2.0 // MCQ1=1, MCQ2=2, ident3=1, ident4=2, essay=0
        } else if spec.student_id == STUDENT_02_ID {
            1.0 // only MCQ1 correct
        } else {
            0.0
        };

        assessment_repo
            .mark_submitted(spec.sub_id)
            .await
            .expect("seed: mark_submitted");

        assessment_repo
            .update_submission_scores(spec.sub_id, total)
            .await
            .expect("seed: update_submission_scores");
    }
}

async fn step6b_assignment_submissions(db: &DatabaseConnection) {
    let assignment_repo = AssignmentRepository::new(db.clone());
    let submitted = days_ago(4);
    let graded_at = days_ago(3);

    // student_01 → Math HW1 (graded)
    assignment_repo
        .create_submission(ASSIGN_MATH_HW1_ID, STUDENT_01_ID, Some(SUB_ASSIGN_S01_HW1))
        .await
        .expect("seed: create assign sub s01_hw1");

    assignment_repo
        .update_submission_text(SUB_ASSIGN_S01_HW1, Some("My completed homework.".to_string()))
        .await
        .expect("seed: update_submission_text s01");

    assignment_repo
        .update_submission_status(SUB_ASSIGN_S01_HW1, "submitted")
        .await
        .expect("seed: update_submission_status s01");

    assignment_repo
        .grade_submission(SUB_ASSIGN_S01_HW1, 45, Some("Good work, minor deductions.".to_string()), Some(TEACHER_01_ID))
        .await
        .expect("seed: grade_submission s01");

    // Patch submitted_at and graded_at
    patch_assign_sub_timestamps(db, SUB_ASSIGN_S01_HW1, submitted, Some(graded_at)).await;

    // student_02 → Math HW1 (ungraded)
    assignment_repo
        .create_submission(ASSIGN_MATH_HW1_ID, STUDENT_02_ID, Some(SUB_ASSIGN_S02_HW1))
        .await
        .expect("seed: create assign sub s02_hw1");

    assignment_repo
        .update_submission_text(SUB_ASSIGN_S02_HW1, Some("My homework attempt.".to_string()))
        .await
        .expect("seed: update_submission_text s02");

    assignment_repo
        .update_submission_status(SUB_ASSIGN_S02_HW1, "submitted")
        .await
        .expect("seed: update_submission_status s02");

    patch_assign_sub_timestamps(db, SUB_ASSIGN_S02_HW1, submitted, None).await;

    // student_01 → Sci Lab (ungraded)
    assignment_repo
        .create_submission(ASSIGN_SCI_LAB_ID, STUDENT_01_ID, Some(SUB_ASSIGN_S01_LAB))
        .await
        .expect("seed: create assign sub s01_lab");

    assignment_repo
        .update_submission_text(SUB_ASSIGN_S01_LAB, Some("My lab report.".to_string()))
        .await
        .expect("seed: update_submission_text s01_lab");

    assignment_repo
        .update_submission_status(SUB_ASSIGN_S01_LAB, "submitted")
        .await
        .expect("seed: update_submission_status s01_lab");

    patch_assign_sub_timestamps(db, SUB_ASSIGN_S01_LAB, submitted, None).await;
}

async fn patch_assign_sub_timestamps(
    db: &DatabaseConnection,
    sub_id: Uuid,
    submitted_at: chrono::NaiveDateTime,
    graded_at: Option<chrono::NaiveDateTime>,
) {
    use ::entity::assignment_submissions;
    let sub = assignment_submissions::Entity::find_by_id(sub_id)
        .one(db).await.expect("seed: find assign sub").unwrap();
    let mut sam: assignment_submissions::ActiveModel = sub.into();
    sam.submitted_at = Set(Some(submitted_at));
    if let Some(ga) = graded_at {
        sam.graded_at = Set(Some(ga));
    }
    sam.update(db).await.expect("seed: patch assign sub timestamps");
}

// ─── Step 7: Learning Materials ──────────────────────────────────────────────

async fn step7_materials(db: &DatabaseConnection) {
    let n = now();

    struct MatSpec {
        id: Uuid,
        class_id: Uuid,
        title: &'static str,
        content: &'static str,
    }

    let specs = vec![
        MatSpec {
            id: MAT_MATH_ID,
            class_id: CLASS_MATH_8A_ID,
            title: "Unit 1: Integer Operations",
            content: "## Integer Operations\n\nIntegers are whole numbers that can be positive, negative, or zero.\n\nOperations on integers follow specific rules for signs.\n\nPractice with number lines helps build intuition.",
        },
        MatSpec {
            id: MAT_SCI_ID,
            class_id: CLASS_SCI_8A_ID,
            title: "Unit 1: Volcanoes",
            content: "## Volcanoes\n\nVolcanoes are openings in the Earth's crust where magma reaches the surface.\n\nThe Philippines lies on the Pacific Ring of Fire.\n\nGeothermal energy can be harnessed from volcanic activity.",
        },
        MatSpec {
            id: MAT_ADVISORY_ID,
            class_id: CLASS_ADVISORY_8A_ID,
            title: "Advisory Guidelines",
            content: "## Advisory Class Guidelines\n\nThis advisory class covers homeroom activities and student welfare.\n\nAttendance and punctuality are expected.",
        },
        MatSpec {
            id: MAT_ARCHIVED_ID,
            class_id: CLASS_ARCHIVED_10A_ID,
            title: "Old Reference Material",
            content: "## Old Reference\n\nThis material is from a previous term.\n\nPlease refer to updated resources.",
        },
    ];

    for spec in specs {
        let model = learning_materials::ActiveModel {
            id: Set(spec.id),
            class_id: Set(spec.class_id),
            title: Set(spec.title.to_string()),
            description: Set(Some("E2E test material".to_string())),
            content_text: Set(Some(spec.content.to_string())),
            order_index: Set(0),
            created_at: Set(n),
            updated_at: Set(n),
            deleted_at: Set(None),
        };
        model.insert(db).await.expect("seed: learning_material");
    }

    println!("  [seed] learning materials done");
}

// ─── Step 8: Grading ─────────────────────────────────────────────────────────

async fn step8_grading(db: &DatabaseConnection) {
    let grade_repo = GradeComputationRepository::new(db.clone());

    // Setup grade records for the 2 active subject classes
    for class_id in [CLASS_MATH_8A_ID, CLASS_SCI_8A_ID] {
        grade_repo
            .setup_defaults(class_id, "math_sci")
            .await
            .expect("seed: setup_defaults");
    }

    // Grade items for assessments are auto-created by publish_assessment service.
    // We only need to create manual items for assessments that need it (all were published via service,
    // so grade items are already present). Nothing extra needed here.

    // Populate grade scores for enrolled students
    // Math 8A students: student_01, student_02, student_03
    // Sci 8A students:  student_01, student_02

    // Find grade items by source
    let assess_items: Vec<(Uuid, Vec<Uuid>)> = vec![
        (ASSESS_MATH_QUIZ1_ID, vec![STUDENT_01_ID, STUDENT_02_ID, STUDENT_03_ID]),
        (ASSESS_MATH_QUIZ2_ID, vec![STUDENT_01_ID, STUDENT_02_ID, STUDENT_03_ID]),
        (ASSESS_SCI_TEST1_ID, vec![STUDENT_01_ID, STUDENT_02_ID]),
        (ASSESS_SCI_TEST2_ID, vec![STUDENT_01_ID, STUDENT_02_ID]),
    ];

    let assign_items: Vec<(Uuid, Vec<Uuid>)> = vec![
        (ASSIGN_MATH_HW1_ID, vec![STUDENT_01_ID, STUDENT_02_ID, STUDENT_03_ID]),
        (ASSIGN_SCI_LAB_ID, vec![STUDENT_01_ID, STUDENT_02_ID]),
        (ASSIGN_MATH_PROJECT_ID, vec![STUDENT_01_ID, STUDENT_02_ID, STUDENT_03_ID]),
    ];

    let n = now();
    for (source_id, students) in assess_items {
        let item = grade_repo
            .find_by_source("assessment", &source_id.to_string())
            .await
            .expect("seed: find_by_source assess");

        if let Some(item) = item {
            for student_id in students {
                let score = get_student_assess_score(student_id, source_id);
                grade_scores::ActiveModel {
                    id: Set(Uuid::new_v4()),
                    grade_item_id: Set(item.id),
                    student_id: Set(student_id),
                    score: Set(Some(score)),
                    is_auto_populated: Set(true),
                    override_score: Set(None),
                    created_at: Set(n),
                    updated_at: Set(n),
                    deleted_at: Set(None),
                }.insert(db).await.expect("seed: insert grade_score assess");
            }
        }
    }

    for (source_id, students) in assign_items {
        let item = grade_repo
            .find_by_source("assignment", &source_id.to_string())
            .await
            .expect("seed: find_by_source assign");

        if let Some(item) = item {
            for student_id in students {
                let score = get_student_assign_score(student_id, source_id);
                grade_scores::ActiveModel {
                    id: Set(Uuid::new_v4()),
                    grade_item_id: Set(item.id),
                    student_id: Set(student_id),
                    score: Set(Some(score)),
                    is_auto_populated: Set(true),
                    override_score: Set(None),
                    created_at: Set(n),
                    updated_at: Set(n),
                    deleted_at: Set(None),
                }.insert(db).await.expect("seed: insert grade_score assign");
            }
        }
    }

    // Period grades — direct ActiveModel insert to avoid raw-SQL UUID mismatch.
    let computed = days_ago(1);
    for (class_id, student_id, initial_grade) in [
        (CLASS_MATH_8A_ID, STUDENT_01_ID, 85.0_f64),
        (CLASS_MATH_8A_ID, STUDENT_02_ID, 72.0_f64),
        (CLASS_MATH_8A_ID, STUDENT_03_ID, 65.0_f64),
        (CLASS_SCI_8A_ID, STUDENT_01_ID, 88.0_f64),
        (CLASS_SCI_8A_ID, STUDENT_02_ID, 70.0_f64),
    ] {
        let transmuted = crate::modules::grading::helpers::deped_weights::transmute_grade(initial_grade);
        period_grades::ActiveModel {
            id: Set(Uuid::new_v4()),
            class_id: Set(class_id),
            student_id: Set(student_id),
            grading_period_number: Set(1),
            initial_grade: Set(Some(initial_grade)),
            transmuted_grade: Set(Some(transmuted)),
            is_locked: Set(false),
            computed_at: Set(Some(computed)),
            created_at: Set(n),
            updated_at: Set(n),
            deleted_at: Set(None),
        }.insert(db).await.expect("seed: insert period_grade");
    }

    println!("  [seed] grading done");
}

fn get_student_assess_score(student_id: Uuid, assessment_id: Uuid) -> f64 {
    match (student_id, assessment_id) {
        (id, _) if id == STUDENT_01_ID => 6.0,  // out of 11 total (1+2+1+2+5)
        (id, _) if id == STUDENT_02_ID => 1.0,
        _ => 0.0,
    }
}

fn get_student_assign_score(student_id: Uuid, assignment_id: Uuid) -> f64 {
    if assignment_id == ASSIGN_MATH_HW1_ID {
        match student_id {
            id if id == STUDENT_01_ID => 45.0,
            id if id == STUDENT_02_ID => 0.0, // ungraded → 0
            _ => 0.0,
        }
    } else {
        0.0 // future / ungraded
    }
}
