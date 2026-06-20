//! Quarter 4 fixtures for demo seeding: Physics.

pub mod assessments;
pub mod assignments;
pub mod materials;
pub mod answers;

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;

pub fn demo_assessments_q4(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    assessments::demo_assessments_q4(ctx)
}

pub fn demo_assignments_q4(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    assignments::demo_assignments_q4(ctx)
}

pub fn demo_materials_q4(ctx: &SeedContext) -> Vec<MaterialSpec> {
    materials::demo_materials_q4(ctx)
}

pub fn demo_answers_q4() -> super::QuarterAnswers {
    answers::demo_answers_q4()
}
