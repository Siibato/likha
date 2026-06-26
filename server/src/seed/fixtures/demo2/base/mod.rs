//! Re-exports all static fixtures for demo-2 seed.

pub mod attendance;
pub mod classes;
pub mod competencies;
pub mod core_values;
pub mod enrollments;
pub mod learner_details;
pub mod previous_attendance;
pub mod previous_subjects;
pub mod school;
pub mod school_history;
pub mod tos;
pub mod users;

pub use attendance::demo2_attendance;
pub use classes::demo2_classes;
pub use competencies::demo2_competencies;
pub use core_values::demo2_core_values;
pub use enrollments::demo2_enrollments;
pub use learner_details::demo2_learner_details;
pub use previous_attendance::demo2_previous_attendance;
pub use previous_subjects::demo2_previous_subjects;
pub use school::demo2_school_details;
pub use school_history::demo2_school_history;
pub use tos::demo2_tos;
pub use users::demo2_users;
