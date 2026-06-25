//! Re-exports all T2 fixtures for demo-2 seed.

pub mod assessments;
pub mod assignments;
pub mod materials;
pub mod answers;

pub use assessments::demo2_assessments_t2;
pub use assignments::demo2_assignments_t2;
pub use materials::demo2_materials_t2;
pub use answers::{demo2_answers_sci_t2, demo2_answers_math_t2}; // English, AP, Filipino, TLE disconnected from seed
