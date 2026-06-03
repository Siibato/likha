//! Manual seeding scenario (stub for future implementation).
//!
//! This will seed the full dataset as specified in SEEDING_DATA_SPECIFICATIONS.md:
//! - 76 users, 15 classes, 440 enrollments
//! - 15 TOS with 60 competencies
//! - 30-45 assessments with 450-1350 questions
//! - 30-45 assignments
//! - ~1200 assessment submissions, ~1200 assignment submissions
//! - etc.

use sea_orm::DatabaseConnection;

use crate::seed::tools::SeedContext;

pub async fn seed_manual_world(_db: &DatabaseConnection) -> Result<(), sea_orm::DbErr> {
    let _ctx = SeedContext::new();

    // TODO: Implement full manual seeding
    // This will use generators for submissions and grading
    // while reusing all the inserters

    println!("Manual seed not yet implemented.");
    Ok(())
}
