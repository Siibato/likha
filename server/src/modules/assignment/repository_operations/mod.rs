// Assignment operations
pub mod create_assignment;
pub mod find_by_id;
pub mod find_by_class_id;
pub mod find_all;
pub mod find_published_by_class_id;
pub mod update_assignment;
pub mod publish_assignment;
pub mod unpublish_assignment;
pub mod soft_delete;
pub mod get_max_order_index;
pub mod reorder_assignments;

// Submission operations (flattened from submissions subdirectory)
pub mod create_submission;
pub mod find_submission_by_id;
pub mod find_submissions_by_assignment;
pub mod find_student_submission;
pub mod update_submission_text;
pub mod update_submission_status;
pub mod grade_submission;
pub mod return_submission;
pub mod count_submissions_by_assignment;
pub mod count_submissions_by_assignments;
pub mod count_graded_by_assignment;
pub mod count_graded_by_assignments;
pub mod find_published_by_class_ids;
pub mod find_student_submissions_for_assignments;

// File operations (flattened from submissions subdirectory)
pub mod save_file;
pub mod find_file_by_id;
pub mod find_files_by_submission;
pub mod soft_delete_file;
pub mod find_student_name;
pub mod count_active_by_hash;
pub mod find_active_file_path_by_hash;

// Re-export all operations
pub use create_assignment::*;
pub use find_by_id::*;
pub use find_by_class_id::*;
pub use find_all::*;
pub use find_published_by_class_id::*;
pub use update_assignment::*;
pub use publish_assignment::*;
pub use unpublish_assignment::*;
pub use soft_delete::*;
pub use get_max_order_index::*;
pub use reorder_assignments::*;

pub use create_submission::*;
pub use find_submission_by_id::*;
pub use find_submissions_by_assignment::*;
pub use find_student_submission::*;
pub use update_submission_text::*;
pub use update_submission_status::*;
pub use grade_submission::*;
pub use return_submission::*;
pub use count_submissions_by_assignment::*;
pub use count_submissions_by_assignments::*;
pub use count_graded_by_assignment::*;
pub use count_graded_by_assignments::*;
pub use find_published_by_class_ids::*;
pub use find_student_submissions_for_assignments::*;

pub use save_file::*;
pub use find_file_by_id::*;
pub use find_files_by_submission::*;
pub use soft_delete_file::*;
pub use find_student_name::*;
pub use count_active_by_hash::*;
pub use find_active_file_path_by_hash::*;
