//! Term 3 fixtures for demo seeding: Chemistry.

pub mod answers;
pub mod assessments;
pub mod assignments;
pub mod materials;

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;

pub fn demo_assessments_t3(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    assessments::demo_assessments_t3(ctx)
}

pub fn demo_assignments_t3(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    assignments::demo_assignments_t3(ctx)
}

pub fn demo_materials_t3(ctx: &SeedContext) -> Vec<MaterialSpec> {
    materials::demo_materials_t3(ctx)
}

pub fn demo_answers_t3() -> super::TermAnswers {
    answers::demo_answers_t3()
}
