//! Re-exports all static fixtures for the demo seed.

pub mod classes;
pub mod competencies;
pub mod enrollments;
pub mod school;
pub mod tos;
pub mod users;

pub use classes::demo_classes;
pub use competencies::demo_competencies;
pub use enrollments::demo_enrollments;
pub use school::demo_school_settings;
pub use tos::demo_tos;
pub use users::demo_users;
