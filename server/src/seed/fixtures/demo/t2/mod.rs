//! Term 2 fixtures for demo seeding: Genetics & Heredity.

pub mod assessments;
pub mod assignments;
pub mod materials;
pub mod answers;

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;

pub fn demo_assessments_t2(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    assessments::demo_assessments_t2(ctx)
}

pub fn demo_assignments_t2(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    assignments::demo_assignments_t2(ctx)
}

pub fn demo_materials_t2(ctx: &SeedContext) -> Vec<MaterialSpec> {
    materials::demo_materials_t2(ctx)
}

pub fn demo_answers_t2() -> super::TermAnswers {
    answers::demo_answers_t2()
}
