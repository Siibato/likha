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

use super::fixtures::*;
use super::ids::*;

pub async fn seed_e2e_world(db: &DatabaseConnection) {
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

    users::Entity::delete_many()
        .filter(users::Column::Role.eq("admin"))
        .exec(db)
        .await
        .expect("seed: delete default admin");

    for spec in users() {
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

    for spec in classes() {
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

    for enr in teacher_enrollments() {
        class_repo.add_participant(enr.class_id, enr.user_id).await.expect("seed: add teacher");
    }

    for enr in student_enrollments() {
        class_repo.add_participant(enr.class_id, enr.user_id).await.expect("seed: add student");
    }

    println!("  [seed] classes & enrollment done");
}

// ─── Step 3: TOS & Competencies ──────────────────────────────────────────────

async fn step3_tos(db: &DatabaseConnection) {
    let tos_repo = TosRepository::new(db.clone());

    for t in tos_fixtures() {
        tos_repo.create_tos(
            t.id, t.class_id, t.period,
            t.title, t.template_type, t.total_items, t.time_limit_unit,
            t.ww_percent, t.pt_percent, t.qa_percent,
            t.easy_percent, t.average_percent, t.difficult_percent,
            t.remembering_percent, t.understanding_percent, t.applying_percent,
        ).await.expect("seed: TOS");
    }

    for c in competency_fixtures() {
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

    let n = now();
    for spec in assessment_fixtures() {
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

        let a = ::entity::assessments::Entity::find_by_id(spec.id)
            .one(db).await.expect("seed: find assess").unwrap();
        let mut am: ::entity::assessments::ActiveModel = a.into();
        am.created_at = Set(created);
        am.updated_at = Set(created);
        am.update(db).await.expect("seed: patch assess");

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

            let q = assessment_questions::Entity::find_by_id(qid)
                .one(db).await.expect("seed: find q").unwrap();
            let mut qam: assessment_questions::ActiveModel = q.into();
            qam.tos_competency_id = Set(Some(comp_id.to_string()));
            qam.difficulty = Set(Some(difficulty.to_string()));
            qam.cognitive_level = Set(Some(cog_level.to_string()));
            qam.update(db).await.expect("seed: patch question");
        }

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

        for (qid, answer_text) in [(spec.questions.q3, "42"), (spec.questions.q4, "principle")] {
            let ak = answer_keys::ActiveModel {
                id: Set(Uuid::new_v4()),
                question_id: Set(qid),
            };
            let inserted_ak = ak.insert(db).await.expect("seed: answer_key");

            let acc1 = answer_key_acceptable_answers::ActiveModel {
                id: Set(Uuid::new_v4()),
                answer_key_id: Set(inserted_ak.id),
                answer_text: Set(answer_text.to_string()),
            };
            acc1.insert(db).await.expect("seed: acceptable_answer 1");

            let variant = format!("{}-variant", answer_text);
            let acc2 = answer_key_acceptable_answers::ActiveModel {
                id: Set(Uuid::new_v4()),
                answer_key_id: Set(inserted_ak.id),
                answer_text: Set(variant),
            };
            acc2.insert(db).await.expect("seed: acceptable_answer 2");
        }

        let essay_ak = answer_keys::ActiveModel {
            id: Set(Uuid::new_v4()),
            question_id: Set(spec.questions.q5),
        };
        essay_ak.insert(db).await.expect("seed: essay answer_key");

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

    let n = now();
    for spec in assignment_fixtures() {
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

    let questions_map = assessment_question_sets();

    for spec in &assessment_submission_fixtures() {
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

        let total: f64 = if spec.student_id == STUDENT_01_ID {
            1.0 + 2.0 + 1.0 + 2.0 // MCQ1=1, MCQ2=2, ident3=1, ident4=2, essay=0
        } else if spec.student_id == STUDENT_02_ID {
            1.0 
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

    for sub in assignment_submission_fixtures() {
        assignment_repo
            .create_submission(sub.assignment_id, sub.student_id, Some(sub.sub_id))
            .await
            .expect("seed: create assign sub");

        if let Some(text) = sub.text {
            assignment_repo
                .update_submission_text(sub.sub_id, Some(text.to_string()))
                .await
                .expect("seed: update_submission_text");
        }

        assignment_repo
            .update_submission_status(sub.sub_id, sub.status)
            .await
            .expect("seed: update_submission_status");

        if let (Some(grade), Some(feedback), Some(graded_by)) = (sub.grade, sub.feedback, sub.graded_by) {
            assignment_repo
                .grade_submission(sub.sub_id, grade, Some(feedback.to_string()), Some(graded_by))
                .await
                .expect("seed: grade_submission");
        }

        let submitted_at = days_ago(sub.submitted_offset as u64);
        let graded_at = sub.graded_offset.map(|o| days_ago(o as u64));
        patch_assign_sub_timestamps(db, sub.sub_id, submitted_at, graded_at).await;
    }
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

    for spec in material_fixtures() {
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

    for class_id in [CLASS_MATH_8A_ID, CLASS_SCI_8A_ID] {
        grade_repo
            .setup_defaults(class_id, "math_sci")
            .await
            .expect("seed: setup_defaults");
    }

    let n = now();

    for fixture in assessment_grade_scores() {
        let item = grade_repo
            .find_by_source(fixture.source_type, &fixture.source_id.to_string())
            .await
            .expect("seed: find_by_source assess");

        if let Some(item) = item {
            for &student_id in fixture.students {
                let score = get_student_assess_score(student_id, fixture.source_id);
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

    for fixture in assignment_grade_scores() {
        let item = grade_repo
            .find_by_source(fixture.source_type, &fixture.source_id.to_string())
            .await
            .expect("seed: find_by_source assign");

        if let Some(item) = item {
            for &student_id in fixture.students {
                let score = get_student_assign_score(student_id, fixture.source_id);
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

    let computed = days_ago(1);
    for (class_id, student_id, initial_grade) in period_grade_fixtures() {
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

