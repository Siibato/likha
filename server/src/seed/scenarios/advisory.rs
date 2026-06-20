//! Advisory seeding scenario.
//!
//! Creates 1 teacher + 30 students, 4 classes (3 subject + 1 advisory),
//! full gradebook for subject classes, plus full SF10 data (learner details,
//! attendance, core values, school history with previous subjects & attendance).

use sea_orm::DatabaseConnection;

use crate::seed::fixtures::advisory as fixtures;
use crate::seed::generators::advisory_grades;
use crate::seed::inserters;
use crate::seed::tools::{disable_foreign_keys, enable_foreign_keys, SeedContext};
use crate::utils::AppError;

pub async fn seed_advisory_world(db: &DatabaseConnection) -> Result<(), AppError> {
    let ctx = SeedContext::new();

    // Build all fixture specs
    let school = fixtures::advisory_school_details(&ctx);
    let users = fixtures::advisory_users(&ctx);
    let classes = fixtures::advisory_classes(&ctx);
    let enrollments = fixtures::advisory_enrollments();
    let learner_details = fixtures::advisory_learner_details();
    let attendance = fixtures::advisory_attendance();
    let core_values = fixtures::advisory_core_values();
    let school_history = fixtures::advisory_school_history();
    let previous_subjects = fixtures::advisory_previous_subjects();
    let previous_attendance = fixtures::advisory_previous_attendance();

    let students: Vec<_> = users.iter().filter(|u| u.role == "student").cloned().collect();

    // Generate gradebook data for subject classes
    let grade_records = advisory_grades::generate_grade_records();
    let grade_items = advisory_grades::generate_grade_items();
    let grade_scores = advisory_grades::generate_grade_scores(&students, &enrollments, &grade_items);
    let term_grades = advisory_grades::generate_term_grades(
        &students, &grade_records, &grade_scores, &grade_items, &enrollments, &ctx,
    );

    // Insert in FK-safe order
    disable_foreign_keys(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;

    inserters::school::insert_school_details(db, &school).await?;
    inserters::users::insert_users(db, &users).await?;
    inserters::learner_details::insert_learner_details(db, &learner_details).await?;
    inserters::classes::insert_classes(db, &classes).await?;
    inserters::classes::insert_enrollments(db, &enrollments).await?;

    inserters::grading::insert_grade_records(db, &grade_records, ctx.now()).await?;
    inserters::grading::insert_grade_items(db, &grade_items, ctx.now()).await?;
    inserters::grading::insert_grade_scores(db, &grade_scores, ctx.now()).await?;
    inserters::grading::insert_term_grades(db, &term_grades, ctx.now()).await?;

    inserters::student_records::insert_attendance_records(db, &attendance).await?;
    inserters::student_records::insert_core_values_records(db, &core_values).await?;

    inserters::school_history::insert_school_history(db, &school_history).await?;
    inserters::school_history::insert_previous_subjects(db, &previous_subjects).await?;
    inserters::school_history::insert_previous_attendance(db, &previous_attendance).await?;

    enable_foreign_keys(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;

    println!(
        "Advisory seed complete: {} users, {} classes, {} enrollments, {} learner details, \
         {} grade records, {} grade items, {} grade scores, {} term grades, \
         {} attendance records, {} core values records, \
         {} school history, {} previous subjects, {} previous attendance",
        users.len(), classes.len(), enrollments.len(), learner_details.len(),
        grade_records.len(), grade_items.len(), grade_scores.len(), term_grades.len(),
        attendance.len(), core_values.len(),
        school_history.len(), previous_subjects.len(), previous_attendance.len()
    );

    Ok(())
}
