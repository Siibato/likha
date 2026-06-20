// CRUD operations
pub mod create_assignment;
pub mod get_assignments;
pub mod get_assignment_detail;
pub mod get_student_assignments;
pub mod update_assignment;
pub mod publish_assignment;
pub mod unpublish_assignment;
pub mod soft_delete;
pub mod reorder_assignments;

// Metadata operations
pub mod get_assignments_metadata;

// Submission operations
pub mod create_or_get_submission;
pub mod get_submission_detail;
pub mod submit_assignment;

// File operations
pub mod upload_file;
pub mod download_file;
pub mod delete_file;

// Grading operations
pub mod get_submissions;
pub mod get_student_assignment_submission;
pub mod get_student_assignment_submissions;
pub mod grade_submission;
pub mod return_submission;

// Helper operations
pub mod build_submission_response;

// Re-export all operations
pub use create_assignment::*;
pub use get_assignments::*;
pub use get_assignment_detail::*;
pub use get_student_assignments::*;
pub use update_assignment::*;
pub use publish_assignment::*;
pub use unpublish_assignment::*;
pub use soft_delete::*;
pub use reorder_assignments::*;

pub use get_assignments_metadata::*;

pub use create_or_get_submission::*;
pub use get_submission_detail::*;
pub use submit_assignment::*;

pub use upload_file::*;
pub use download_file::*;
pub use delete_file::*;

pub use get_submissions::*;
pub use get_student_assignment_submission::*;
pub use get_student_assignment_submissions::*;
pub use grade_submission::*;
pub use return_submission::*;
