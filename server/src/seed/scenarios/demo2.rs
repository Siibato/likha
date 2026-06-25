//! Demo-2 seeding scenario.
//!
//! Creates an expanded dataset: 6 teachers, 30 students, 7 classes (1 advisory + 6 subjects),
//! 3 terms of assessments, assignments, and learning modules for each subject,
//! with tiered student submissions and derived grades.

use sea_orm::DatabaseConnection;

use crate::seed::fixtures::demo2 as fixtures;
use crate::seed::generators;
use crate::seed::inserters;
use crate::seed::manifest::{build_manifest, export_manifest};
use crate::seed::tools::{disable_foreign_keys, enable_foreign_keys, SeedContext};
use crate::utils::AppError;

pub async fn seed_demo2_world(db: &DatabaseConnection) -> Result<(), AppError> {
    let ctx = SeedContext::new();

    // Build all fixture specs
    let school = fixtures::base::demo2_school_details(&ctx);
    let users = fixtures::base::demo2_users(&ctx);
    let classes = fixtures::base::demo2_classes(&ctx);
    let enrollments = fixtures::base::demo2_enrollments();
    let learner_details = fixtures::base::demo2_learner_details();
    let attendance = fixtures::base::demo2_attendance();
    let core_values = fixtures::base::demo2_core_values();
    let school_history = fixtures::base::demo2_school_history();
    let previous_subjects = fixtures::base::demo2_previous_subjects();
    let previous_attendance = fixtures::base::demo2_previous_attendance();
    let tos_list = fixtures::base::demo2_tos();
    let competencies = fixtures::base::demo2_competencies();

    // Term 1 fixtures
    let t1_assessments = fixtures::t1::demo2_assessments_t1(&ctx);
    let t1_assignments = fixtures::t1::demo2_assignments_t1(&ctx);
    let t1_materials = fixtures::t1::demo2_materials_t1(&ctx);

    // Term 2 fixtures
    let t2_assessments = fixtures::t2::demo2_assessments_t2(&ctx);
    let t2_assignments = fixtures::t2::demo2_assignments_t2(&ctx);
    let t2_materials = fixtures::t2::demo2_materials_t2(&ctx);

    // Term 3 fixtures
    let t3_assessments = fixtures::t3::demo2_assessments_t3(&ctx);
    let t3_assignments = fixtures::t3::demo2_assignments_t3(&ctx);
    let t3_materials = fixtures::t3::demo2_materials_t3(&ctx);

    // Combine all terms
    let mut assessments = Vec::new();
    assessments.extend(t1_assessments);
    assessments.extend(t2_assessments);
    assessments.extend(t3_assessments);

    let mut assignments = Vec::new();
    assignments.extend(t1_assignments);
    assignments.extend(t2_assignments);
    assignments.extend(t3_assignments);

    let mut materials = Vec::new();
    materials.extend(t1_materials);
    materials.extend(t2_materials);
    materials.extend(t3_materials);

    // Build answer bank for all subjects and terms
    let mut answers = std::collections::HashMap::new();
    answers.insert(("sci", "t1"), fixtures::t1::demo2_answers_sci_t1());
    answers.insert(("eng", "t1"), fixtures::t1::demo2_answers_eng_t1());
    answers.insert(("math", "t1"), fixtures::t1::demo2_answers_math_t1());
    answers.insert(("ap", "t1"), fixtures::t1::demo2_answers_ap_t1());
    answers.insert(("fil", "t1"), fixtures::t1::demo2_answers_fil_t1());
    answers.insert(("tle", "t1"), fixtures::t1::demo2_answers_tle_t1());

    answers.insert(("sci", "t2"), fixtures::t2::demo2_answers_sci_t2());
    answers.insert(("eng", "t2"), fixtures::t2::demo2_answers_eng_t2());
    answers.insert(("math", "t2"), fixtures::t2::demo2_answers_math_t2());
    answers.insert(("ap", "t2"), fixtures::t2::demo2_answers_ap_t2());
    answers.insert(("fil", "t2"), fixtures::t2::demo2_answers_fil_t2());
    answers.insert(("tle", "t2"), fixtures::t2::demo2_answers_tle_t2());

    answers.insert(("sci", "t3"), fixtures::t3::demo2_answers_sci_t3());
    answers.insert(("eng", "t3"), fixtures::t3::demo2_answers_eng_t3());
    answers.insert(("math", "t3"), fixtures::t3::demo2_answers_math_t3());
    answers.insert(("ap", "t3"), fixtures::t3::demo2_answers_ap_t3());
    answers.insert(("fil", "t3"), fixtures::t3::demo2_answers_fil_t3());
    answers.insert(("tle", "t3"), fixtures::t3::demo2_answers_tle_t3());

    let teachers: Vec<_> = users
        .iter()
        .filter(|u| u.role == "teacher")
        .cloned()
        .collect();
    let students: Vec<_> = users
        .iter()
        .filter(|u| u.role == "student")
        .cloned()
        .collect();

    // Generate submissions using tiered answer bank
    let assessment_submissions = generators::demo2_submissions::generate_demo2_assessment_submissions(
        &ctx,
        &assessments,
        &students,
        &enrollments,
        &answers,
    );
    let assignment_submissions = generators::demo2_submissions::generate_demo2_assignment_submissions(
        &ctx,
        &assignments,
        &students,
        &teachers,
        &enrollments,
        &answers,
    );

    // Generate gradebook data derived from submissions
    let grade_records = generators::demo2_grades::generate_demo2_grade_records(&classes);
    let grade_items =
        generators::demo2_grades::generate_demo2_grade_items(&assessments, &assignments, &ctx);
    let grade_scores = generators::demo2_grades::generate_demo2_grade_scores(
        &grade_items,
        &students,
        &assessment_submissions,
        &assignment_submissions,
        &enrollments,
    );
    let term_grades = generators::demo2_grades::generate_demo2_term_grades(
        &grade_records,
        &grade_scores,
        &grade_items,
        &students,
        &enrollments,
        &ctx,
    );

    // Insert everything in FK-safe order
    disable_foreign_keys(db)
        .await
        .map_err(|e| AppError::InternalServerError(e.to_string()))?;

    inserters::school::insert_school_details(db, &school).await?;
    inserters::users::insert_users(db, &users).await?;
    inserters::learner_details::insert_learner_details(db, &learner_details).await?;
    inserters::classes::insert_classes(db, &classes).await?;
    inserters::classes::insert_enrollments(db, &enrollments).await?;
    inserters::tos::insert_tos(db, &tos_list).await?;
    inserters::tos::insert_competencies(db, &competencies).await?;

    inserters::assessments::insert_assessments_with_questions(db, &assessments).await?;

    inserters::assignments::insert_assignments(db, &assignments).await?;

    inserters::materials::insert_materials(db, &materials).await?;

    inserters::submissions::insert_assessment_submissions(db, &assessment_submissions).await?;
    inserters::submissions::insert_assignment_submissions(db, &assignment_submissions).await?;

    inserters::grading::insert_grade_records(db, &grade_records, ctx.now()).await?;
    inserters::grading::insert_grade_items(db, &grade_items, ctx.now()).await?;
    inserters::grading::insert_grade_scores(db, &grade_scores, ctx.now()).await?;
    inserters::grading::insert_term_grades(db, &term_grades, ctx.now()).await?;

    inserters::student_records::insert_attendance_records(db, &attendance).await?;
    inserters::student_records::insert_core_values_records(db, &core_values).await?;

    inserters::school_history::insert_school_history(db, &school_history).await?;
    inserters::school_history::insert_previous_subjects(db, &previous_subjects).await?;
    inserters::school_history::insert_previous_attendance(db, &previous_attendance).await?;

    enable_foreign_keys(db)
        .await
        .map_err(|e| AppError::InternalServerError(e.to_string()))?;

    // Build and export manifest
    let manifest = build_manifest(&users, &classes, &assessments, &assignments);
    if let Err(e) = export_manifest(&manifest, "demo2_manifest.json") {
        eprintln!("Warning: failed to export demo2 manifest: {}", e);
    }

    println!(
        "Demo-2 seed complete: {} users, {} classes, {} enrollments, {} learner details, {} TOS, {} competencies, {} assessments, {} assignments, {} materials, {} assessment submissions, {} assignment submissions, {} grade records, {} grade items, {} grade scores, {} term grades, {} attendance records, {} core values records, {} school history, {} previous subjects, {} previous attendance",
        users.len(), classes.len(), enrollments.len(), learner_details.len(), tos_list.len(), competencies.len(),
        assessments.len(), assignments.len(), materials.len(), assessment_submissions.len(),
        assignment_submissions.len(), grade_records.len(), grade_items.len(), grade_scores.len(),
        term_grades.len(), attendance.len(), core_values.len(), school_history.len(),
        previous_subjects.len(), previous_attendance.len()
    );

    Ok(())
}
