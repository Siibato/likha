//! Re-exports all T3 fixtures for demo-2 seed.

pub mod assessments;
pub mod assignments;
pub mod materials;
pub mod answers;

pub use assessments::demo2_assessments_t3;
pub use assignments::demo2_assignments_t3;
pub use materials::demo2_materials_t3;
pub use answers::{demo2_answers_sci_t3, demo2_answers_eng_t3, demo2_answers_math_t3, demo2_answers_ap_t3, demo2_answers_fil_t3, demo2_answers_tle_t3};
