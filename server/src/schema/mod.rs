pub mod admin_schema;
pub mod setup_schema;
pub mod assessment_schema;
pub mod auth_schema;
pub mod common;
pub mod grading_schema;
pub mod learning_material_schema;
pub mod tasks_schema;
pub mod tos_schema;

// Re-export for backward compatibility during migration
pub use crate::modules::class::schema as class_schema;
pub use crate::modules::assignment::schema as assignment_schema;
