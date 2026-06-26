//! E2E seeding scenario.

use sea_orm::DatabaseConnection;

use crate::seed::fixtures::e2e as fixtures;
use crate::seed::inserters;
use crate::seed::tools::{disable_foreign_keys, enable_foreign_keys, SeedContext};
use crate::utils::AppError;

pub async fn seed_e2e_world(db: &DatabaseConnection) -> Result<(), AppError> {
    let ctx = SeedContext::new();

    let school = fixtures::e2e_school_details(&ctx);
    let users = fixtures::e2e_users(&ctx);
    let classes = fixtures::e2e_classes(&ctx);
    let enrollments = fixtures::e2e_enrollments();
    let tos = fixtures::e2e_tos();
    let competencies = fixtures::e2e_competencies();
    let assessments = fixtures::e2e_assessments(&ctx);
    let assignments = fixtures::e2e_assignments(&ctx);
    let materials = fixtures::e2e_materials(&ctx);

    disable_foreign_keys(db)
        .await
        .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    inserters::school::insert_school_details(db, &school).await?;
    inserters::users::insert_users(db, &users).await?;
    inserters::classes::insert_classes(db, &classes).await?;
    inserters::classes::insert_enrollments(db, &enrollments).await?;
    inserters::tos::insert_tos(db, &tos).await?;
    inserters::tos::insert_competencies(db, &competencies).await?;

    inserters::assessments::insert_assessments_with_questions(db, &assessments).await?;

    inserters::assignments::insert_assignments(db, &assignments).await?;

    inserters::materials::insert_materials(db, &materials).await?;

    let assessment_submissions = fixtures::e2e_assessment_submissions(&ctx);
    inserters::submissions::insert_assessment_submissions(db, &assessment_submissions).await?;

    let assignment_submissions = fixtures::e2e_assignment_submissions(&ctx);
    inserters::submissions::insert_assignment_submissions(db, &assignment_submissions).await?;

    let grade_records = fixtures::e2e_grade_records();
    inserters::grading::insert_grade_records(db, &grade_records, ctx.now()).await?;

    enable_foreign_keys(db)
        .await
        .map_err(|e| AppError::InternalServerError(e.to_string()))?;

    println!("E2E seed complete.");
    Ok(())
}
