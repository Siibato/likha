use chrono::NaiveDateTime;
use sea_orm::DatabaseConnection;
use serde_json::Value;
use uuid::Uuid;

use crate::modules::sync::repository_operations::manifest as ops;
pub use ops::{ManifestEntry, PaginatedRecords};

/// Repository for building and querying manifests
#[derive(Clone)]
pub struct ManifestRepository {
    db: DatabaseConnection,
}

impl ManifestRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    // ─── Section A: Manifest Queries ──────────────────────────────────────────

    pub async fn get_classes_manifest(&self, class_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<ManifestEntry>> {
        ops::get_classes_manifest(&self.db, class_ids).await
    }

    pub async fn get_all_assessment_submissions_manifest(&self, assessment_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<ManifestEntry>> {
        ops::get_all_assessment_submissions_manifest(&self.db, assessment_ids).await
    }

    pub async fn get_enrollments_manifest(&self, class_ids: Vec<Uuid>, user_id: Uuid, user_role: &str) -> crate::utils::AppResult<Vec<ManifestEntry>> {
        ops::get_enrollments_manifest(&self.db, class_ids, user_id, user_role).await
    }

    pub async fn get_assessments_manifest(&self, class_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<ManifestEntry>> {
        ops::get_assessments_manifest(&self.db, class_ids).await
    }

    pub async fn get_questions_manifest(&self, assessment_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<ManifestEntry>> {
        ops::get_questions_manifest(&self.db, assessment_ids).await
    }

    pub async fn get_assessment_submissions_manifest(&self, user_id: Uuid, assessment_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<ManifestEntry>> {
        ops::get_assessment_submissions_manifest(&self.db, user_id, assessment_ids).await
    }

    pub async fn get_published_assessments_manifest(&self, class_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<ManifestEntry>> {
        ops::get_published_assessments_manifest(&self.db, class_ids).await
    }

    pub async fn get_assignments_manifest(&self, class_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<ManifestEntry>> {
        ops::get_assignments_manifest(&self.db, class_ids).await
    }

    pub async fn get_published_assignments_manifest(&self, class_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<ManifestEntry>> {
        ops::get_published_assignments_manifest(&self.db, class_ids).await
    }

    pub async fn get_assignment_submissions_manifest(&self, user_id: Uuid, assignment_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<ManifestEntry>> {
        ops::get_assignment_submissions_manifest(&self.db, user_id, assignment_ids).await
    }

    pub async fn get_all_assignment_submissions_manifest(&self, assignment_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<ManifestEntry>> {
        ops::get_all_assignment_submissions_manifest(&self.db, assignment_ids).await
    }

    pub async fn get_materials_manifest(&self, class_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<ManifestEntry>> {
        ops::get_materials_manifest(&self.db, class_ids).await
    }

    pub async fn get_activity_logs_manifest(&self, user_id: Uuid, user_role: &str) -> crate::utils::AppResult<Vec<ManifestEntry>> {
        ops::get_activity_logs_manifest(&self.db, user_id, user_role).await
    }

    pub async fn get_activity_logs_paginated(&self, log_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_activity_logs_paginated(&self.db, log_ids, limit).await
    }

    // ─── Section B: Paginated Full-Data Queries ───────────────────────────────

    pub async fn get_classes_paginated(&self, class_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_classes_paginated(&self.db, class_ids, limit).await
    }

    pub async fn get_assessments_paginated(&self, assessment_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_assessments_paginated(&self.db, assessment_ids, limit).await
    }

    pub async fn get_assignments_paginated(&self, assignment_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_assignments_paginated(&self.db, assignment_ids, limit).await
    }

    pub async fn get_materials_paginated(&self, material_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_materials_paginated(&self.db, material_ids, limit).await
    }

    pub async fn get_assessments_for_classes(&self, class_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_assessments_for_classes(&self.db, class_ids, limit).await
    }

    pub async fn get_assignments_for_classes(&self, class_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_assignments_for_classes(&self.db, class_ids, limit).await
    }

    pub async fn get_materials_for_classes(&self, class_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_materials_for_classes(&self.db, class_ids, limit).await
    }

    pub async fn get_enrollments_paginated(&self, enrollment_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_enrollments_paginated(&self.db, enrollment_ids, limit).await
    }

    pub async fn get_questions_paginated(&self, question_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_questions_paginated(&self.db, question_ids, limit).await
    }

    pub async fn get_users_paginated(&self, user_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_users_paginated(&self.db, user_ids, limit).await
    }

    pub async fn get_student_submissions_for_assessments(&self, user_id: Uuid, assessment_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_student_submissions_for_assessments(&self.db, user_id, assessment_ids, limit).await
    }

    pub async fn get_student_assignment_submissions_for_assignments(&self, user_id: Uuid, assignment_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_student_assignment_submissions_for_assignments(&self.db, user_id, assignment_ids, limit).await
    }

    pub async fn get_all_assessment_submissions_for_assessments(&self, assessment_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_all_assessment_submissions_for_assessments(&self.db, assessment_ids, limit).await
    }

    pub async fn get_all_assignment_submissions_for_assignments(&self, assignment_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_all_assignment_submissions_for_assignments(&self.db, assignment_ids, limit).await
    }

    pub async fn get_material_files_for_materials(&self, material_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_material_files_for_materials(&self.db, material_ids).await
    }

    pub async fn get_submission_files_for_submissions(&self, submission_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_submission_files_for_submissions(&self.db, submission_ids).await
    }

    // ─── Section C: Delta / Since Queries ────────────────────────────────────

    pub async fn get_classes_since(&self, class_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_classes_since(&self.db, class_ids, since).await
    }

    pub async fn get_assessments_since(&self, assessment_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_assessments_since(&self.db, assessment_ids, since).await
    }

    pub async fn get_assignments_since(&self, assignment_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_assignments_since(&self.db, assignment_ids, since).await
    }

    pub async fn get_materials_since(&self, material_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_materials_since(&self.db, material_ids, since).await
    }

    pub async fn get_enrollments_since(&self, enrollment_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_enrollments_since(&self.db, enrollment_ids, since).await
    }

    pub async fn get_questions_since(&self, question_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_questions_since(&self.db, question_ids, since).await
    }

    pub async fn get_assessment_submissions_since(&self, user_id: Uuid, submission_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_assessment_submissions_since(&self.db, user_id, submission_ids, since).await
    }

    pub async fn get_assignment_submissions_since(&self, user_id: Uuid, submission_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_assignment_submissions_since(&self.db, user_id, submission_ids, since).await
    }

    pub async fn get_activity_logs_since(&self, log_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_activity_logs_since(&self.db, log_ids, since).await
    }

    // ─── Section E: Grading Sync Queries ─────────────────────────────────────

    pub async fn get_grade_configs_for_classes(&self, class_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_grade_configs_for_classes(&self.db, class_ids).await
    }

    pub async fn get_grade_items_for_classes(&self, class_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_grade_items_for_classes(&self.db, class_ids).await
    }

    pub async fn get_all_grade_scores(&self, grade_item_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_all_grade_scores(&self.db, grade_item_ids).await
    }

    pub async fn get_student_grade_scores(&self, student_id: Uuid, grade_item_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_student_grade_scores(&self.db, student_id, grade_item_ids).await
    }

    pub async fn get_all_period_grades(&self, class_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_all_period_grades(&self.db, class_ids).await
    }

    pub async fn get_table_of_specifications_for_classes(&self, class_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_table_of_specifications_for_classes(&self.db, class_ids).await
    }

    pub async fn get_tos_competencies_for_tos_ids(&self, tos_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_tos_competencies_for_tos_ids(&self.db, tos_ids).await
    }

    pub async fn get_student_period_grades(&self, student_id: Uuid, class_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_student_period_grades(&self.db, student_id, class_ids).await
    }

    pub async fn get_grade_configs_since(&self, class_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_grade_configs_since(&self.db, class_ids, since).await
    }

    pub async fn get_grade_items_since(&self, class_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_grade_items_since(&self.db, class_ids, since).await
    }

    pub async fn get_all_grade_scores_since(&self, grade_item_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_all_grade_scores_since(&self.db, grade_item_ids, since).await
    }

    pub async fn get_student_grade_scores_since(&self, student_id: Uuid, grade_item_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_student_grade_scores_since(&self.db, student_id, grade_item_ids, since).await
    }

    pub async fn get_all_period_grades_since(&self, class_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_all_period_grades_since(&self.db, class_ids, since).await
    }

    pub async fn get_student_period_grades_since(&self, student_id: Uuid, class_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_student_period_grades_since(&self.db, student_id, class_ids, since).await
    }

    pub async fn get_table_of_specifications_since(&self, class_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_table_of_specifications_since(&self.db, class_ids, since).await
    }

    pub async fn get_tos_competencies_since(&self, class_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_tos_competencies_since(&self.db, class_ids, since).await
    }

    pub async fn get_school_settings_since(&self, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_school_settings_since(&self.db, since).await
    }

    pub async fn get_grade_item_ids_for_classes(&self, class_ids: Vec<Uuid>) -> crate::utils::AppResult<Vec<Uuid>> {
        ops::get_grade_item_ids_for_classes(&self.db, class_ids).await
    }

    // ─── Section F: Student Records Sync Queries ─────────────────────────────

    pub async fn get_learner_details_for_students(&self, student_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_learner_details_for_students(&self.db, student_ids, limit).await
    }

    pub async fn get_learner_details_since(&self, student_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_learner_details_since(&self.db, student_ids, since).await
    }

    pub async fn get_attendance_for_classes(&self, class_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_attendance_for_classes(&self.db, class_ids, limit).await
    }

    pub async fn get_attendance_since(&self, class_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_attendance_since(&self.db, class_ids, since).await
    }

    pub async fn get_core_values_for_classes(&self, class_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_core_values_for_classes(&self.db, class_ids, limit).await
    }

    pub async fn get_core_values_since(&self, class_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_core_values_since(&self.db, class_ids, since).await
    }

    pub async fn get_school_history_for_students(&self, student_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_school_history_for_students(&self.db, student_ids, limit).await
    }

    pub async fn get_school_history_since(&self, student_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_school_history_since(&self.db, student_ids, since).await
    }

    pub async fn get_previous_subjects_for_students(&self, student_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_previous_subjects_for_students(&self.db, student_ids, limit).await
    }

    pub async fn get_previous_subjects_since(&self, student_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_previous_subjects_since(&self.db, student_ids, since).await
    }

    pub async fn get_previous_attendance_for_students(&self, student_ids: Vec<Uuid>, limit: i64) -> crate::utils::AppResult<PaginatedRecords> {
        ops::get_previous_attendance_for_students(&self.db, student_ids, limit).await
    }

    pub async fn get_previous_attendance_since(&self, student_ids: Vec<Uuid>, since: NaiveDateTime) -> crate::utils::AppResult<Vec<Value>> {
        ops::get_previous_attendance_since(&self.db, student_ids, since).await
    }
}
