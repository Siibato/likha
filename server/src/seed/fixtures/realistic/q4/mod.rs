//! Quarter 4 fixtures for realistic seeding.

pub mod assessments;
pub mod assignments;

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;

pub fn realistic_assessments_q4(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    assessments::realistic_assessments_q4(ctx)
}

pub fn realistic_assignments_q4(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    assignments::realistic_assignments_q4(ctx)
}
