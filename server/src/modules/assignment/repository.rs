use sea_orm::DatabaseConnection;
use uuid::Uuid;

use ::entity::{assignment_submissions, assignments, submission_files, users};
use crate::modules::assignment::repository_operations as ops;
use crate::utils::AppResult;

pub struct AssignmentRepository {
    db: DatabaseConnection,
}

impl AssignmentRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn create_assignment(
        &self,
        class_id: Uuid,
        title: String,
        instructions: String,
        total_points: i32,
        allows_text_submission: bool,
        allows_file_submission: bool,
        allowed_file_types: Option<String>,
        max_file_size_mb: Option<i32>,
        due_at: chrono::NaiveDateTime,
        order_index: i32,
        client_id: Option<Uuid>,
        is_published: bool,
        term_number: Option<i32>,
        component: Option<String>,
    ) -> AppResult<assignments::Model> {
        ops::create_assignment(&self.db, class_id, title, instructions, total_points, allows_text_submission, allows_file_submission, allowed_file_types, max_file_size_mb, due_at, order_index, client_id, is_published, term_number, component).await
    }

    pub async fn find_by_id(&self, id: Uuid) -> AppResult<Option<assignments::Model>> {
        ops::find_by_id(&self.db, id).await
    }

    pub async fn find_by_class_id(&self, class_id: Uuid) -> AppResult<Vec<assignments::Model>> {
        ops::find_by_class_id(&self.db, class_id).await
    }

    pub async fn find_published_by_class_id(&self, class_id: Uuid) -> AppResult<Vec<assignments::Model>> {
        ops::find_published_by_class_id(&self.db, class_id).await
    }

    pub async fn find_published_by_class_ids(&self, class_ids: &[Uuid]) -> AppResult<Vec<assignments::Model>> {
        ops::find_published_by_class_ids(&self.db, class_ids).await
    }

    pub async fn update_assignment(
        &self,
        id: Uuid,
        title: Option<String>,
        instructions: Option<String>,
        total_points: Option<i32>,
        allows_text_submission: Option<bool>,
        allows_file_submission: Option<bool>,
        allowed_file_types: Option<Option<String>>,
        max_file_size_mb: Option<Option<i32>>,
        due_at: Option<chrono::NaiveDateTime>,
        term_number: Option<Option<i32>>,
        component: Option<Option<String>>,
    ) -> AppResult<assignments::Model> {
        ops::update_assignment(&self.db, id, title, instructions, total_points, allows_text_submission, allows_file_submission, allowed_file_types, max_file_size_mb, due_at, term_number, component).await
    }

    pub async fn publish_assignment(&self, id: Uuid) -> AppResult<assignments::Model> {
        ops::publish_assignment(&self.db, id).await
    }

    pub async fn unpublish_assignment(&self, id: Uuid) -> AppResult<assignments::Model> {
        ops::unpublish_assignment(&self.db, id).await
    }

    pub async fn create_submission(
        &self,
        assignment_id: Uuid,
        student_id: Uuid,
        submission_id: Option<Uuid>,
    ) -> AppResult<assignment_submissions::Model> {
        ops::create_submission(&self.db, assignment_id, student_id, submission_id).await
    }

    pub async fn find_submission_by_id(&self, id: Uuid) -> AppResult<Option<assignment_submissions::Model>> {
        ops::find_submission_by_id(&self.db, id).await
    }

    pub async fn find_submissions_by_assignment(
        &self,
        assignment_id: Uuid,
    ) -> AppResult<Vec<(assignment_submissions::Model, Option<users::Model>)>> {
        ops::find_submissions_by_assignment(&self.db, assignment_id).await
    }

    pub async fn find_student_submission(
        &self,
        assignment_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<Option<assignment_submissions::Model>> {
        ops::find_student_submission(&self.db, assignment_id, student_id).await
    }

    pub async fn update_submission_text(
        &self,
        id: Uuid,
        text_content: Option<String>,
    ) -> AppResult<assignment_submissions::Model> {
        ops::update_submission_text(&self.db, id, text_content).await
    }

    pub async fn update_submission_status(
        &self,
        id: Uuid,
        status: &str,
    ) -> AppResult<assignment_submissions::Model> {
        ops::update_submission_status(&self.db, id, status).await
    }

    pub async fn grade_submission(
        &self,
        id: Uuid,
        points: i32,
        feedback: Option<String>,
        graded_by: Option<Uuid>,
    ) -> AppResult<assignment_submissions::Model> {
        ops::grade_submission(&self.db, id, points, feedback, graded_by).await
    }

    pub async fn return_submission(&self, id: Uuid) -> AppResult<assignment_submissions::Model> {
        ops::return_submission(&self.db, id).await
    }

    pub async fn count_submissions_by_assignment(&self, assignment_id: Uuid) -> AppResult<usize> {
        ops::count_submissions_by_assignment(&self.db, assignment_id).await
    }

    pub async fn count_submissions_by_assignments(&self, assignment_ids: &[Uuid]) -> AppResult<std::collections::HashMap<Uuid, usize>> {
        ops::count_submissions_by_assignments(&self.db, assignment_ids).await
    }

    pub async fn count_graded_by_assignment(&self, assignment_id: Uuid) -> AppResult<usize> {
        ops::count_graded_by_assignment(&self.db, assignment_id).await
    }

    pub async fn count_graded_by_assignments(&self, assignment_ids: &[Uuid]) -> AppResult<std::collections::HashMap<Uuid, usize>> {
        ops::count_graded_by_assignments(&self.db, assignment_ids).await
    }

    pub async fn find_student_submissions_for_assignments(
        &self,
        assignment_ids: &[Uuid],
        student_id: Uuid,
    ) -> AppResult<std::collections::HashMap<Uuid, assignment_submissions::Model>> {
        ops::find_student_submissions_for_assignments(&self.db, assignment_ids, student_id).await
    }

    pub async fn save_file(
        &self,
        submission_id: Uuid,
        file_name: String,
        file_type: String,
        file_size: i64,
        file_path: String,
        file_hash: String,
    ) -> AppResult<submission_files::Model> {
        ops::save_file(&self.db, submission_id, file_name, file_type, file_size, file_path, file_hash).await
    }

    pub async fn find_active_file_path_by_hash(&self, hash: &str) -> AppResult<Option<String>> {
        ops::find_active_file_path_by_hash(&self.db, hash).await
    }

    pub async fn count_active_by_hash(&self, hash: &str, exclude_id: Uuid) -> AppResult<i64> {
        ops::count_active_by_hash(&self.db, hash, exclude_id).await
    }

    pub async fn soft_delete_file(&self, id: Uuid) -> AppResult<()> {
        ops::soft_delete_file(&self.db, id).await
    }

    pub async fn find_file_by_id(&self, id: Uuid) -> AppResult<Option<submission_files::Model>> {
        ops::find_file_by_id(&self.db, id).await
    }

    pub async fn find_files_by_submission(
        &self,
        submission_id: Uuid,
    ) -> AppResult<Vec<submission_files::Model>> {
        ops::find_files_by_submission(&self.db, submission_id).await
    }

    pub async fn find_student_name(&self, student_id: Uuid) -> AppResult<(String, String)> {
        ops::find_student_name(&self.db, student_id).await
    }

    pub async fn find_all(&self) -> AppResult<Vec<assignments::Model>> {
        ops::find_all(&self.db).await
    }

    pub async fn soft_delete(&self, id: Uuid) -> AppResult<()> {
        ops::soft_delete(&self.db, id).await
    }

    pub async fn get_max_order_index(&self, class_id: Uuid) -> AppResult<i32> {
        ops::get_max_order_index(&self.db, class_id).await
    }

    pub async fn reorder_assignments(&self, _class_id: Uuid, assignment_ids: Vec<Uuid>) -> AppResult<()> {
        ops::reorder_assignments(&self.db, _class_id, assignment_ids).await
    }
}
