//! Demo seeding scenario.
//!
//! Creates a focused dataset: 1 teacher, 30 students, 2 classes,
//! 4 terms of assessments, assignments, and learning modules,
//! with tiered student submissions and derived grades.

use sea_orm::DatabaseConnection;

use crate::seed::fixtures::demo as fixtures;
use crate::seed::generators;
use crate::seed::inserters;
use crate::seed::manifest::{build_manifest, export_manifest};
use crate::seed::tools::{disable_foreign_keys, enable_foreign_keys, SeedContext};
use crate::utils::AppError;

pub async fn seed_demo_world(db: &DatabaseConnection) -> Result<(), AppError> {
    let ctx = SeedContext::new();

    // Build all fixture specs
    let school = fixtures::demo_school_details(&ctx);
    let users = fixtures::demo_users(&ctx);
    let classes = fixtures::demo_classes(&ctx);
    let enrollments = fixtures::demo_enrollments();
    let learner_details = fixtures::demo_learner_details();
    let tos_list = fixtures::demo_tos();
    let competencies = fixtures::demo_competencies();
    let assessments = fixtures::demo_assessments(&ctx);
    let assignments = fixtures::demo_assignments(&ctx);
    let materials = fixtures::demo_materials(&ctx);
    let answers = fixtures::demo_answers();

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
    let assessment_submissions = generators::demo_submissions::generate_assessment_submissions(
        &ctx,
        &assessments,
        &students,
        &enrollments,
        &answers,
    );
    let assignment_submissions = generators::demo_submissions::generate_assignment_submissions(
        &ctx,
        &assignments,
        &students,
        &teachers,
        &enrollments,
        &answers,
    );

    // Generate gradebook data derived from submissions
    let grade_records = generators::demo_grades::generate_grade_records(&classes);
    let grade_items =
        generators::demo_grades::generate_grade_items(&assessments, &assignments, &ctx);
    let grade_scores = generators::demo_grades::generate_grade_scores(
        &grade_items,
        &students,
        &assessment_submissions,
        &assignment_submissions,
        &enrollments,
    );
    let term_grades = generators::demo_grades::generate_term_grades(
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

    for spec in &assessments {
        inserters::assessments::insert_assessment_with_questions(db, spec).await?;
    }

    for spec in &assignments {
        inserters::assignments::insert_assignment(db, spec).await?;
    }

    inserters::materials::insert_materials(db, &materials).await?;

    inserters::submissions::insert_assessment_submissions(db, &assessment_submissions).await?;
    inserters::submissions::insert_assignment_submissions(db, &assignment_submissions).await?;

    inserters::grading::insert_grade_records(db, &grade_records, ctx.now()).await?;
    inserters::grading::insert_grade_items(db, &grade_items, ctx.now()).await?;
    inserters::grading::insert_grade_scores(db, &grade_scores, ctx.now()).await?;
    inserters::grading::insert_term_grades(db, &term_grades, ctx.now()).await?;

    enable_foreign_keys(db)
        .await
        .map_err(|e| AppError::InternalServerError(e.to_string()))?;

    // Build and export manifest
    let manifest = build_manifest(&users, &classes, &assessments, &assignments);
    if let Err(e) = export_manifest(&manifest, "demo_manifest.json") {
        eprintln!("Warning: failed to export demo manifest: {}", e);
    }

    println!(
        "Demo seed complete: {} users, {} classes, {} enrollments, {} learner details, {} TOS, {} competencies, {} assessments, {} assignments, {} materials, {} assessment submissions, {} assignment submissions, {} grade records, {} grade items, {} grade scores, {} term grades",
        users.len(), classes.len(), enrollments.len(), learner_details.len(), tos_list.len(), competencies.len(),
        assessments.len(), assignments.len(), materials.len(), assessment_submissions.len(),
        assignment_submissions.len(), grade_records.len(), grade_items.len(), grade_scores.len(),
        term_grades.len()
    );

    Ok(())
}
