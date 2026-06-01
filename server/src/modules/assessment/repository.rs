use sea_orm::DatabaseConnection;
use uuid::Uuid;

use ::entity::{answer_key_acceptable_answers, answer_keys, assessment_questions, assessment_submissions, assessments, question_choices, submission_answer_items, submission_answers};
use crate::utils::AppResult;
use crate::modules::assessment::repository_operations as ops;
pub use ops::AnswerDetail;

pub struct AssessmentRepository {
    db: DatabaseConnection,
}

impl AssessmentRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn create_assessment(
        &self,
        class_id: Uuid,
        title: String,
        description: Option<String>,
        time_limit_minutes: i32,
        open_at: chrono::NaiveDateTime,
        close_at: chrono::NaiveDateTime,
        show_results_immediately: bool,
        order_index: i32,
        client_id: Option<Uuid>,
        is_published: bool,
        grading_period_number: Option<i32>,
        component: Option<String>,
        tos_id: Option<String>,
    ) -> AppResult<assessments::Model> {
        ops::create_assessment(&self.db, class_id, title, description, time_limit_minutes, open_at, close_at, show_results_immediately, order_index, client_id, is_published, grading_period_number, component, tos_id).await
    }

    pub async fn find_by_id(&self, id: Uuid) -> AppResult<Option<assessments::Model>> {
        ops::find_by_id(&self.db, id).await
    }

    pub async fn find_by_class_id(&self, class_id: Uuid) -> AppResult<Vec<assessments::Model>> {
        ops::find_by_class_id(&self.db, class_id).await
    }

    pub async fn find_published_by_class_id(&self, class_id: Uuid) -> AppResult<Vec<assessments::Model>> {
        ops::find_published_by_class_id(&self.db, class_id).await
    }

    pub async fn update_assessment(
        &self,
        id: Uuid,
        title: Option<String>,
        description: Option<String>,
        time_limit_minutes: Option<i32>,
        open_at: Option<chrono::NaiveDateTime>,
        close_at: Option<chrono::NaiveDateTime>,
        show_results_immediately: Option<bool>,
        grading_period_number: Option<Option<i32>>,
        component: Option<Option<String>>,
        tos_id: Option<Option<String>>,
    ) -> AppResult<assessments::Model> {
        ops::update_assessment(&self.db, id, title, description, time_limit_minutes, open_at, close_at, show_results_immediately, grading_period_number, component, tos_id).await
    }

    pub async fn publish_assessment(&self, id: Uuid) -> AppResult<assessments::Model> {
        ops::publish_assessment(&self.db, id).await
    }

    pub async fn unpublish_assessment(&self, id: Uuid) -> AppResult<assessments::Model> {
        ops::unpublish_assessment(&self.db, id).await
    }

    pub async fn release_results(&self, id: Uuid) -> AppResult<assessments::Model> {
        ops::release_results(&self.db, id).await
    }

    pub async fn update_total_points(&self, assessment_id: Uuid) -> AppResult<()> {
        ops::update_total_points(&self.db, assessment_id).await
    }

    // ===== QUESTIONS =====

    pub async fn add_question(
        &self,
        assessment_id: Uuid,
        question_type: String,
        question_text: String,
        points: i32,
        order_index: i32,
        is_multi_select: bool,
        client_id: Option<Uuid>,
    ) -> AppResult<assessment_questions::Model> {
        ops::add_question(&self.db, assessment_id, question_type, question_text, points, order_index, is_multi_select, client_id).await
    }

    pub async fn find_question_by_id(&self, id: Uuid) -> AppResult<Option<assessment_questions::Model>> {
        ops::find_question_by_id(&self.db, id).await
    }

    pub async fn find_questions_by_assessment_id(
        &self,
        assessment_id: Uuid,
    ) -> AppResult<Vec<assessment_questions::Model>> {
        ops::find_questions_by_assessment_id(&self.db, assessment_id).await
    }

    pub async fn update_question(
        &self,
        id: Uuid,
        question_text: Option<String>,
        points: Option<i32>,
        order_index: Option<i32>,
        is_multi_select: Option<bool>,
    ) -> AppResult<assessment_questions::Model> {
        ops::update_question(&self.db, id, question_text, points, order_index, is_multi_select).await
    }

    pub async fn delete_question(&self, id: Uuid) -> AppResult<()> {
        ops::delete_question(&self.db, id).await
    }

    // ===== CHOICES =====

    pub async fn add_choice(
        &self,
        question_id: Uuid,
        choice_text: String,
        is_correct: bool,
        order_index: i32,
    ) -> AppResult<question_choices::Model> {
        ops::add_choice(&self.db, question_id, choice_text, is_correct, order_index).await
    }

    pub async fn find_choices_by_question_id(
        &self,
        question_id: Uuid,
    ) -> AppResult<Vec<question_choices::Model>> {
        ops::find_choices_by_question_id(&self.db, question_id).await
    }

    pub async fn delete_choices_by_question_id(&self, question_id: Uuid) -> AppResult<()> {
        ops::delete_choices_by_question_id(&self.db, question_id).await
    }

    // ===== CORRECT ANSWERS =====

    pub async fn add_correct_answer(
        &self,
        question_id: Uuid,
        answer_text: String,
    ) -> AppResult<answer_key_acceptable_answers::Model> {
        ops::add_correct_answer(&self.db, question_id, answer_text).await
    }

    pub async fn find_correct_answers_by_question_id(
        &self,
        question_id: Uuid,
    ) -> AppResult<Vec<answer_key_acceptable_answers::Model>> {
        ops::find_correct_answers_by_question_id(&self.db, question_id).await
    }

    pub async fn delete_correct_answers_by_question_id(&self, question_id: Uuid) -> AppResult<()> {
        ops::delete_correct_answers_by_question_id(&self.db, question_id).await
    }

    pub async fn find_all(&self) -> AppResult<Vec<assessments::Model>> {
        ops::find_all(&self.db).await
    }

    pub async fn soft_delete(&self, id: Uuid) -> AppResult<()> {
        ops::soft_delete(&self.db, id).await
    }

    pub async fn get_max_order_index(&self, class_id: Uuid) -> AppResult<i32> {
        ops::get_max_order_index(&self.db, class_id).await
    }

    pub async fn reorder_assessments(&self, _class_id: Uuid, assessment_ids: Vec<Uuid>) -> AppResult<()> {
        ops::reorder_assessments(&self.db, _class_id, assessment_ids).await
    }

    pub async fn reorder_questions(&self, _assessment_id: Uuid, question_ids: Vec<Uuid>) -> AppResult<()> {
        ops::reorder_questions(&self.db, _assessment_id, question_ids).await
    }

    pub async fn find_enumeration_items_for_question(&self, question_id: Uuid) -> AppResult<Vec<(answer_keys::Model, Vec<answer_key_acceptable_answers::Model>)>> {
        ops::find_enumeration_items_for_question(&self.db, question_id).await
    }

    /// Creates one answer_key row + its acceptable answer rows for one enumeration slot.
    pub async fn add_enumeration_item(
        &self,
        question_id: Uuid,
        acceptable_answers: Vec<String>,
    ) -> AppResult<answer_keys::Model> {
        ops::add_enumeration_item(&self.db, question_id, acceptable_answers).await
    }

    /// Deletes ALL answer_key rows for a question (cascades to acceptable_answers).
    pub async fn delete_all_answer_keys_for_question(&self, question_id: Uuid) -> AppResult<()> {
        ops::delete_all_answer_keys_for_question(&self.db, question_id).await
    }

    // ===== SUBMISSIONS =====

    pub async fn create_submission(
        &self,
        assessment_id: Uuid,
        student_id: Uuid,
        submission_id: Option<Uuid>,
    ) -> AppResult<assessment_submissions::Model> {
        ops::create_submission(&self.db, assessment_id, student_id, submission_id).await
    }

    pub async fn find_submission_by_id(&self, id: Uuid) -> AppResult<Option<assessment_submissions::Model>> {
        ops::find_submission_by_id(&self.db, id).await
    }

    pub async fn find_submissions_by_assessment_id(&self, assessment_id: Uuid) -> AppResult<Vec<assessment_submissions::Model>> {
        ops::find_submissions_by_assessment_id(&self.db, assessment_id).await
    }

    pub async fn find_by_student_and_assessment(&self, student_id: Uuid, assessment_id: Uuid) -> AppResult<Option<assessment_submissions::Model>> {
        ops::find_by_student_and_assessment(&self.db, student_id, assessment_id).await
    }

    pub async fn count_submissions_by_assessment_id(&self, assessment_id: Uuid) -> AppResult<usize> {
        ops::count_submissions_by_assessment_id(&self.db, assessment_id).await
    }

    pub async fn mark_submitted(&self, submission_id: Uuid) -> AppResult<assessment_submissions::Model> {
        ops::mark_submitted(&self.db, submission_id).await
    }

    pub async fn update_submission_scores(&self, submission_id: Uuid, total_points: f64) -> AppResult<()> {
        ops::update_submission_scores(&self.db, submission_id, total_points).await
    }

    pub async fn soft_delete_submissions_by_assessment(&self, assessment_id: Uuid) -> AppResult<()> {
        ops::soft_delete_submissions_by_assessment(&self.db, assessment_id).await
    }

    pub async fn upsert_answer(&self, submission_id: Uuid, question_id: Uuid, answer_text: Option<String>) -> AppResult<submission_answers::Model> {
        ops::upsert_answer(&self.db, submission_id, question_id, answer_text).await
    }

    pub async fn find_answers_by_submission_id(&self, submission_id: Uuid) -> AppResult<Vec<submission_answers::Model>> {
        ops::find_answers_by_submission_id(&self.db, submission_id).await
    }

    pub async fn find_answer_by_id(&self, id: Uuid) -> AppResult<Option<submission_answers::Model>> {
        ops::find_answer_by_id(&self.db, id).await
    }

    pub async fn update_answer_grade(&self, answer_id: Uuid, is_auto_correct: Option<bool>, points_awarded: f64) -> AppResult<submission_answers::Model> {
        ops::update_answer_grade(&self.db, answer_id, is_auto_correct, points_awarded).await
    }

    pub async fn override_answer(&self, answer_id: Uuid, is_correct: bool, points: f64) -> AppResult<submission_answers::Model> {
        ops::override_answer(&self.db, answer_id, is_correct, points).await
    }

    pub async fn save_answer_items(&self, submission_answer_id: Uuid, items: Vec<(Option<Uuid>, Option<Uuid>, Option<String>, bool)>) -> AppResult<()> {
        ops::save_answer_items(&self.db, submission_answer_id, items).await
    }

    pub async fn find_answer_items_by_submission_answer_id(&self, submission_answer_id: Uuid) -> AppResult<Vec<submission_answer_items::Model>> {
        ops::find_answer_items_by_submission_answer_id(&self.db, submission_answer_id).await
    }

    pub async fn save_answer_choices(&self, submission_answer_id: Uuid, choice_ids: Vec<Uuid>) -> AppResult<()> {
        ops::save_answer_choices(&self.db, submission_answer_id, choice_ids).await
    }

    pub async fn save_answer_text(&self, submission_answer_id: Uuid, answer_text: String) -> AppResult<()> {
        ops::save_answer_text(&self.db, submission_answer_id, answer_text).await
    }

    pub async fn find_answer_choices(&self, submission_answer_id: Uuid) -> AppResult<Vec<Uuid>> {
        ops::find_answer_choices(&self.db, submission_answer_id).await
    }

    pub async fn find_enumeration_answers(&self, submission_answer_id: Uuid) -> AppResult<Vec<String>> {
        ops::find_enumeration_answers(&self.db, submission_answer_id).await
    }

    pub async fn save_enumeration_answers_linked(&self, submission_answer_id: Uuid, items: Vec<(Option<Uuid>, String)>) -> AppResult<()> {
        ops::save_enumeration_answers_linked(&self.db, submission_answer_id, items).await
    }

    pub async fn find_enumeration_answer_items(&self, submission_answer_id: Uuid) -> AppResult<Vec<submission_answer_items::Model>> {
        ops::find_enumeration_answer_items(&self.db, submission_answer_id).await
    }

    pub async fn update_answer_item_correctness(&self, item_id: Uuid, is_correct: bool) -> AppResult<()> {
        ops::update_answer_item_correctness(&self.db, item_id, is_correct).await
    }

    pub async fn get_all_answer_details_for_assessment(&self, assessment_id: Uuid) -> AppResult<Vec<AnswerDetail>> {
        ops::get_all_answer_details_for_assessment(&self.db, assessment_id).await
    }
}
