//! Re-exports all T1 fixtures for demo-2 seed.

pub mod assessments;
pub mod assignments;
pub mod materials;
pub mod answers;

pub use assessments::demo2_assessments_t1;
pub use assignments::demo2_assignments_t1;
pub use materials::demo2_materials_t1;
pub use answers::{demo2_answers_sci_t1, demo2_answers_eng_t1, demo2_answers_math_t1, demo2_answers_ap_t1, demo2_answers_fil_t1, demo2_answers_tle_t1};
