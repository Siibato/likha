//! Pure functions for generating submission data.
//! 
//! For E2E seeding, submissions are explicitly defined in fixtures.
//! For manual seeding, these generators implement deterministic rules
//! (skip patterns, correctness ratios, etc.) from the seeding spec.

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;

pub fn generate_assessment_submissions(
    _ctx: &SeedContext,
    _assessments: &[AssessmentSpec],
    _students: &[UserSpec],
) -> Vec<AssessmentSubmissionSpec> {
    // TODO: Implement for manual seed
    // Rules:
    // - Skip if (student_idx + assessment_idx) % 7 == 0
    // - 90% submitted, 10% in-progress
    // - Correctness: 30% fully correct, 40% mostly correct, 25% mostly wrong, 5% all wrong
    vec![]
}

pub fn generate_assignment_submissions(
    _ctx: &SeedContext,
    _assignments: &[AssignmentSpec],
    _students: &[UserSpec],
) -> Vec<AssignmentSubmissionSpec> {
    // TODO: Implement for manual seed
    // Rules:
    // - Skip if (student_idx + assignment_idx) % 7 == 0
    // - 50% submitted (not graded), 50% graded
    vec![]
}
