//! Manual seeding fixtures (stub for future implementation).
//!
//! This will contain the large-scale seed data:
//! - 76 users (1 admin + 5 teachers + 70 students)
//! - 15 classes
//! - 440 enrollments
//! - 15 TOS with 60 competencies
//! - 30-45 assessments
//! - 30-45 assignments
//! - etc.

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;

pub fn manual_users(_ctx: &SeedContext) -> Vec<UserSpec> {
    // TODO: Implement based on SEEDING_DATA_SPECIFICATIONS.md §3.1
    vec![]
}

pub fn manual_classes(_ctx: &SeedContext) -> Vec<ClassSpec> {
    // TODO: Implement based on SEEDING_DATA_SPECIFICATIONS.md §3.2
    vec![]
}

pub fn manual_enrollments() -> Vec<EnrollmentSpec> {
    // TODO: Implement based on SEEDING_DATA_SPECIFICATIONS.md §3.3
    vec![]
}

pub fn manual_tos() -> Vec<TosSpec> {
    // TODO: Implement based on SEEDING_DATA_SPECIFICATIONS.md §3.4
    vec![]
}

pub fn manual_competencies() -> Vec<CompetencySpec> {
    // TODO: Implement based on SEEDING_DATA_SPECIFICATIONS.md §3.5
    vec![]
}

pub fn manual_assessments(_ctx: &SeedContext) -> Vec<AssessmentSpec> {
    // TODO: Implement based on SEEDING_DATA_SPECIFICATIONS.md §3.6
    vec![]
}

pub fn manual_assignments(_ctx: &SeedContext) -> Vec<AssignmentSpec> {
    // TODO: Implement based on SEEDING_DATA_SPECIFICATIONS.md §3.10
    vec![]
}

pub fn manual_materials(_ctx: &SeedContext) -> Vec<MaterialSpec> {
    // TODO: Implement based on SEEDING_DATA_SPECIFICATIONS.md §3.12
    vec![]
}

pub fn manual_school_settings(_ctx: &SeedContext) -> SchoolSettingsSpec {
    SchoolSettingsSpec {
        id: 1,
        school_code: "SEED-SCHOOL".into(),
        school_name: Some("Likha Test School".into()),
        school_region: Some("NCR".into()),
        school_division: Some("Division of City Schools".into()),
        school_year: Some("2025-2026".into()),
        updated_at: _ctx.now(),
    }
}
