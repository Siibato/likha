use sea_orm::DatabaseConnection;
use uuid::Uuid;

use ::entity::{grade_items, grade_record, grade_scores, learner_details, term_grades};
use crate::utils::AppResult;
use crate::modules::grading::repository_operations as ops;
pub use ops::StudentEnrolledClass;

#[derive(Clone)]
pub struct GradeComputationRepository {
    db: DatabaseConnection,
}

impl GradeComputationRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    // ─── Grade Record ─────────────────────────────────────────────────────────

    pub async fn get_config(&self, class_id: Uuid, term_number: i32) -> AppResult<Option<grade_record::Model>> {
        ops::get_config(&self.db, class_id, term_number).await
    }

    pub async fn get_all_configs(&self, class_id: Uuid) -> AppResult<Vec<grade_record::Model>> {
        ops::get_all_configs(&self.db, class_id).await
    }

    pub async fn upsert_config(&self, class_id: Uuid, term_number: i32, ww_weight: f64, pt_weight: f64, qa_weight: f64) -> AppResult<grade_record::Model> {
        ops::upsert_config(&self.db, class_id, term_number, ww_weight, pt_weight, qa_weight).await
    }

    pub async fn setup_defaults(&self, class_id: Uuid, subject_group: &str) -> AppResult<Vec<grade_record::Model>> {
        ops::setup_defaults(&self.db, class_id, subject_group).await
    }

    // ─── Grade Items ──────────────────────────────────────────────────────────

    pub async fn get_items(&self, class_id: Uuid, term_number: i32) -> AppResult<Vec<grade_items::Model>> {
        ops::get_items(&self.db, class_id, term_number).await
    }

    pub async fn get_items_by_component(&self, class_id: Uuid, term_number: i32, component: &str) -> AppResult<Vec<grade_items::Model>> {
        ops::get_items_by_component(&self.db, class_id, term_number, component).await
    }

    pub async fn find_item(&self, id: Uuid) -> AppResult<Option<grade_items::Model>> {
        ops::find_item(&self.db, id).await
    }

    pub async fn find_by_source(&self, source_type: &str, source_id: &str) -> AppResult<Option<grade_items::Model>> {
        ops::find_by_source(&self.db, source_type, source_id).await
    }

    pub async fn create_item(&self, class_id: Uuid, title: String, component: String, term_number: Option<i32>, total_points: f64, source_type: String, source_id: Option<String>, order_index: i32) -> AppResult<grade_items::Model> {
        ops::create_item(&self.db, class_id, title, component, term_number, total_points, source_type, source_id, order_index).await
    }

    pub async fn update_item(&self, id: Uuid, title: Option<String>, component: Option<String>, total_points: Option<f64>, order_index: Option<i32>, source_type: Option<String>, source_id: Option<String>) -> AppResult<grade_items::Model> {
        ops::update_item(&self.db, id, title, component, total_points, order_index, source_type, source_id).await
    }

    pub async fn soft_delete_item(&self, id: Uuid) -> AppResult<()> {
        ops::soft_delete_item(&self.db, id).await
    }

    // ─── Grade Scores ─────────────────────────────────────────────────────────

    pub async fn get_scores_by_item(&self, grade_item_id: Uuid) -> AppResult<Vec<grade_scores::Model>> {
        ops::get_scores_by_item(&self.db, grade_item_id).await
    }

    pub async fn get_scores_by_student_class_term(&self, student_id: Uuid, class_id: Uuid, term_number: i32) -> AppResult<Vec<grade_scores::Model>> {
        ops::get_scores_by_student_class_term(&self.db, student_id, class_id, term_number).await
    }

    pub async fn upsert_score(&self, grade_item_id: Uuid, student_id: Uuid, score: Option<f64>, is_auto_populated: bool) -> AppResult<grade_scores::Model> {
        ops::upsert_score(&self.db, grade_item_id, student_id, score, is_auto_populated).await
    }

    pub async fn bulk_upsert_scores(&self, grade_item_id: Uuid, scores: Vec<(Uuid, f64)>) -> AppResult<()> {
        ops::bulk_upsert_scores(&self.db, grade_item_id, scores).await
    }

    pub async fn set_override(&self, id: Uuid, override_score: f64) -> AppResult<grade_scores::Model> {
        ops::set_override(&self.db, id, override_score).await
    }

    pub async fn clear_override(&self, id: Uuid) -> AppResult<grade_scores::Model> {
        ops::clear_override(&self.db, id).await
    }

    // ─── Term Grades ────────────────────────────────────────────────────────

    pub async fn get_term_grade(&self, class_id: Uuid, student_id: Uuid, term_number: i32) -> AppResult<Option<term_grades::Model>> {
        ops::get_term_grade(&self.db, class_id, student_id, term_number).await
    }

    pub async fn get_all_for_class(&self, class_id: Uuid, term_number: i32) -> AppResult<Vec<term_grades::Model>> {
        ops::get_all_for_class(&self.db, class_id, term_number).await
    }

    pub async fn get_all_for_student(&self, class_id: Uuid, student_id: Uuid) -> AppResult<Vec<term_grades::Model>> {
        ops::get_all_for_student(&self.db, class_id, student_id).await
    }

    pub async fn upsert_term_grade(&self, class_id: Uuid, student_id: Uuid, term_number: i32, initial_grade: f64, transmuted_grade: i32, is_locked: bool) -> AppResult<term_grades::Model> {
        ops::upsert_term_grade(&self.db, class_id, student_id, term_number, initial_grade, transmuted_grade, is_locked).await
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    pub async fn get_enrolled_student_ids(&self, class_id: Uuid) -> AppResult<Vec<(Uuid, String)>> {
        ops::get_enrolled_student_ids(&self.db, class_id).await
    }

    pub async fn get_learner_details(&self, user_id: Uuid) -> AppResult<Option<learner_details::Model>> {
        ops::get_learner_details(&self.db, user_id).await
    }

    // ─── Cross-Class Queries ──────────────────────────────────────────────────

    pub async fn get_student_enrolled_classes(&self, student_id: Uuid, school_year: Option<&str>) -> AppResult<Vec<StudentEnrolledClass>> {
        ops::get_student_enrolled_classes(&self.db, student_id, school_year).await
    }

    pub async fn get_term_grades_for_student_class(&self, student_id: Uuid, class_id: Uuid) -> AppResult<Vec<term_grades::Model>> {
        ops::get_term_grades_for_student_class(&self.db, student_id, class_id).await
    }
}
