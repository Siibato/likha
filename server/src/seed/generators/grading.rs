//! Pure functions for generating grading data.
//!
//! Grade scores and period grades are computed from submission data
//! using the deterministic rules from the seeding spec.

use uuid::Uuid;

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;

pub fn generate_grade_scores(
    _ctx: &SeedContext,
    _submissions: &[AssessmentSubmissionSpec],
    _grade_item_mappings: &[(Uuid, Uuid)], // (source_id, grade_item_id)
) -> Vec<GradeScoreSpec> {
    // TODO: Implement for manual seed
    // - One score per student per grade item
    // - 5% have override_score set (teacher adjustment)
    vec![]
}

pub fn generate_period_grades(
    _ctx: &SeedContext,
    _classes: &[ClassSpec],
    _students: &[UserSpec],
    _grade_scores: &[GradeScoreSpec],
) -> Vec<PeriodGradeSpec> {
    // TODO: Implement for manual seed
    // - ~2,100 period grades (1 per student per class per period)
    // - Use DepEd transmutation formula
    vec![]
}
