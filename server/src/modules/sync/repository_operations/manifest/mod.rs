use chrono::NaiveDateTime;
use uuid::Uuid;

pub mod helpers;

// Section A: Manifest queries
pub mod get_classes_manifest;
pub mod get_enrollments_manifest;
pub mod get_assessments_manifest;
pub mod get_published_assessments_manifest;
pub mod get_questions_manifest;
pub mod get_assessment_submissions_manifest;
pub mod get_all_assessment_submissions_manifest;
pub mod get_assignments_manifest;
pub mod get_published_assignments_manifest;
pub mod get_assignment_submissions_manifest;
pub mod get_all_assignment_submissions_manifest;
pub mod get_materials_manifest;
pub mod get_activity_logs_manifest;

// Section B: Paginated full-data queries
pub mod get_classes_paginated;
pub mod get_assessments_paginated;
pub mod get_assignments_paginated;
pub mod get_materials_paginated;
pub mod get_assessments_for_classes;
pub mod get_assignments_for_classes;
pub mod get_materials_for_classes;
pub mod get_enrollments_paginated;
pub mod get_questions_paginated;
pub mod get_users_paginated;
pub mod get_student_submissions_for_assessments;
pub mod get_student_assignment_submissions_for_assignments;
pub mod get_all_assessment_submissions_for_assessments;
pub mod get_all_assignment_submissions_for_assignments;
pub mod get_material_files_for_materials;
pub mod get_submission_files_for_submissions;
pub mod get_activity_logs_paginated;

// Section C: Delta/since queries
pub mod get_classes_since;
pub mod get_assessments_since;
pub mod get_assignments_since;
pub mod get_materials_since;
pub mod get_enrollments_since;
pub mod get_questions_since;
pub mod get_assessment_submissions_since;
pub mod get_assignment_submissions_since;
pub mod get_activity_logs_since;

// Section E: Grading sync queries
pub mod get_grade_configs_for_classes;
pub mod get_grade_items_for_classes;
pub mod get_grade_item_ids_for_classes;
pub mod get_all_grade_scores;
pub mod get_student_grade_scores;
pub mod get_all_quarterly_grades;
pub mod get_student_quarterly_grades;
pub mod get_table_of_specifications_for_classes;
pub mod get_tos_competencies_for_tos_ids;
pub mod get_grade_configs_since;
pub mod get_grade_items_since;
pub mod get_all_grade_scores_since;
pub mod get_student_grade_scores_since;
pub mod get_all_quarterly_grades_since;
pub mod get_student_quarterly_grades_since;
pub mod get_table_of_specifications_since;
pub mod get_tos_competencies_since;

/// Record entry in the manifest (id + updated_at + deleted flag)
#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct ManifestEntry {
    pub id: Uuid,
    pub updated_at: NaiveDateTime,
    pub deleted: bool,
}

/// Get records with pagination
#[derive(Debug, Clone)]
pub struct PaginatedRecords {
    pub records: Vec<serde_json::Value>,
}

pub use get_classes_manifest::get_classes_manifest;
pub use get_enrollments_manifest::get_enrollments_manifest;
pub use get_assessments_manifest::get_assessments_manifest;
pub use get_published_assessments_manifest::get_published_assessments_manifest;
pub use get_questions_manifest::get_questions_manifest;
pub use get_assessment_submissions_manifest::get_assessment_submissions_manifest;
pub use get_all_assessment_submissions_manifest::get_all_assessment_submissions_manifest;
pub use get_assignments_manifest::get_assignments_manifest;
pub use get_published_assignments_manifest::get_published_assignments_manifest;
pub use get_assignment_submissions_manifest::get_assignment_submissions_manifest;
pub use get_all_assignment_submissions_manifest::get_all_assignment_submissions_manifest;
pub use get_materials_manifest::get_materials_manifest;
pub use get_activity_logs_manifest::get_activity_logs_manifest;

pub use get_classes_paginated::get_classes_paginated;
pub use get_assessments_paginated::get_assessments_paginated;
pub use get_assignments_paginated::get_assignments_paginated;
pub use get_materials_paginated::get_materials_paginated;
pub use get_assessments_for_classes::get_assessments_for_classes;
pub use get_assignments_for_classes::get_assignments_for_classes;
pub use get_materials_for_classes::get_materials_for_classes;
pub use get_enrollments_paginated::get_enrollments_paginated;
pub use get_questions_paginated::get_questions_paginated;
pub use get_users_paginated::get_users_paginated;
pub use get_student_submissions_for_assessments::get_student_submissions_for_assessments;
pub use get_student_assignment_submissions_for_assignments::get_student_assignment_submissions_for_assignments;
pub use get_all_assessment_submissions_for_assessments::get_all_assessment_submissions_for_assessments;
pub use get_all_assignment_submissions_for_assignments::get_all_assignment_submissions_for_assignments;
pub use get_material_files_for_materials::get_material_files_for_materials;
pub use get_submission_files_for_submissions::get_submission_files_for_submissions;
pub use get_activity_logs_paginated::get_activity_logs_paginated;

pub use get_classes_since::get_classes_since;
pub use get_assessments_since::get_assessments_since;
pub use get_assignments_since::get_assignments_since;
pub use get_materials_since::get_materials_since;
pub use get_enrollments_since::get_enrollments_since;
pub use get_questions_since::get_questions_since;
pub use get_assessment_submissions_since::get_assessment_submissions_since;
pub use get_assignment_submissions_since::get_assignment_submissions_since;
pub use get_activity_logs_since::get_activity_logs_since;

pub use get_grade_configs_for_classes::get_grade_configs_for_classes;
pub use get_grade_items_for_classes::get_grade_items_for_classes;
pub use get_grade_item_ids_for_classes::get_grade_item_ids_for_classes;
pub use get_all_grade_scores::get_all_grade_scores;
pub use get_student_grade_scores::get_student_grade_scores;
pub use get_all_quarterly_grades::get_all_quarterly_grades;
pub use get_student_quarterly_grades::get_student_quarterly_grades;
pub use get_table_of_specifications_for_classes::get_table_of_specifications_for_classes;
pub use get_tos_competencies_for_tos_ids::get_tos_competencies_for_tos_ids;
pub use get_grade_configs_since::get_grade_configs_since;
pub use get_grade_items_since::get_grade_items_since;
pub use get_all_grade_scores_since::get_all_grade_scores_since;
pub use get_student_grade_scores_since::get_student_grade_scores_since;
pub use get_all_quarterly_grades_since::get_all_quarterly_grades_since;
pub use get_student_quarterly_grades_since::get_student_quarterly_grades_since;
pub use get_table_of_specifications_since::get_table_of_specifications_since;
pub use get_tos_competencies_since::get_tos_competencies_since;
