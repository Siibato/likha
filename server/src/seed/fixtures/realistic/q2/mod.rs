//! Quarter 2 fixtures for realistic seeding.

pub mod assessments;
pub mod assignments;

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;

pub fn realistic_assessments_q2(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    assessments::realistic_assessments_q2(ctx)
}

pub fn realistic_assignments_q2(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    assignments::realistic_assignments_q2(ctx)
}
