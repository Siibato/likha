// Assignment operations
pub mod create_assignment;
pub mod find_all;
pub mod find_by_class_id;
pub mod find_by_id;
pub mod find_published_by_class_id;
pub mod get_max_order_index;
pub mod publish_assignment;
pub mod reorder_assignments;
pub mod soft_delete;
pub mod unpublish_assignment;
pub mod update_assignment;

// Submission operations (flattened from submissions subdirectory)
pub mod count_graded_by_assignment;
pub mod count_graded_by_assignments;
pub mod count_submissions_by_assignment;
pub mod count_submissions_by_assignments;
pub mod create_submission;
pub mod find_published_by_class_ids;
pub mod find_student_submission;
pub mod find_student_submissions_for_assignments;
pub mod find_submission_by_id;
pub mod find_submissions_by_assignment;
pub mod grade_submission;
pub mod return_submission;
pub mod update_submission_status;
pub mod update_submission_text;

// File operations (flattened from submissions subdirectory)
pub mod count_active_by_hash;
pub mod find_active_file_path_by_hash;
pub mod find_file_by_id;
pub mod find_files_by_submission;
pub mod find_student_name;
pub mod save_file;
pub mod soft_delete_file;

// Re-export all operations
pub use create_assignment::*;
pub use find_all::*;
pub use find_by_class_id::*;
pub use find_by_id::*;
pub use find_published_by_class_id::*;
pub use get_max_order_index::*;
pub use publish_assignment::*;
pub use reorder_assignments::*;
pub use soft_delete::*;
pub use unpublish_assignment::*;
pub use update_assignment::*;

pub use count_graded_by_assignment::*;
pub use count_graded_by_assignments::*;
pub use count_submissions_by_assignment::*;
pub use count_submissions_by_assignments::*;
pub use create_submission::*;
pub use find_published_by_class_ids::*;
pub use find_student_submission::*;
pub use find_student_submissions_for_assignments::*;
pub use find_submission_by_id::*;
pub use find_submissions_by_assignment::*;
pub use grade_submission::*;
pub use return_submission::*;
pub use update_submission_status::*;
pub use update_submission_text::*;

pub use count_active_by_hash::*;
pub use find_active_file_path_by_hash::*;
pub use find_file_by_id::*;
pub use find_files_by_submission::*;
pub use find_student_name::*;
pub use save_file::*;
pub use soft_delete_file::*;
