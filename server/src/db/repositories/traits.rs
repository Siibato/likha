//! Repository traits for dependency injection and mock-based unit testing.
//!
//! Each trait mirrors the async methods of a concrete repository. Services
//! should be refactored to accept `impl Trait` (or `Arc<dyn Trait>`) instead
//! of the concrete struct to enable mockall-based unit tests.
//!
//! **Note:** Full mock injection requires `mockall = "0.13"` in dev-dependencies.
//! The crate must first be added to the `vendor/` directory.

use async_trait::async_trait;
use uuid::Uuid;

use crate::utils::AppResult;

// ── UserRepository trait ────────────────────────────────────────────────────

#[async_trait]
pub trait UserRepositoryTrait: Send + Sync {
    async fn find_by_username(&self, username: &str) -> AppResult<Option<::entity::users::Model>>;
    async fn find_by_id(&self, id: Uuid) -> AppResult<Option<::entity::users::Model>>;
    async fn set_password(&self, user_id: Uuid, password_hash: String) -> AppResult<::entity::users::Model>;
    async fn clear_password(&self, user_id: Uuid) -> AppResult<::entity::users::Model>;
    async fn update_account_status(&self, user_id: Uuid, status: &str) -> AppResult<::entity::users::Model>;
    async fn find_all_users(&self) -> AppResult<Vec<::entity::users::Model>>;
    async fn search_students(&self, query: &str) -> AppResult<Vec<::entity::users::Model>>;
    async fn revoke_refresh_token(&self, token_id: Uuid) -> AppResult<()>;
    async fn revoke_all_tokens_for_user(&self, user_id: Uuid) -> AppResult<()>;
    async fn soft_delete(&self, user_id: Uuid) -> AppResult<()>;
    async fn find_refresh_token(&self, token_hash: &str) -> AppResult<Option<::entity::refresh_tokens::Model>>;
    async fn create_account(
        &self,
        username: String,
        full_name: String,
        role: String,
        client_id: Option<Uuid>,
    ) -> AppResult<::entity::users::Model>;
}

// ── ActivityLogRepository trait ─────────────────────────────────────────────

#[async_trait]
pub trait ActivityLogRepositoryTrait: Send + Sync {
    async fn create_log(
        &self,
        user_id: Uuid,
        action: &str,
        details: Option<String>,
    ) -> AppResult<::entity::activity_logs::Model>;

    async fn find_by_user_id(&self, user_id: Uuid) -> AppResult<Vec<::entity::activity_logs::Model>>;
}

// ── LoginAttemptRepository trait ────────────────────────────────────────────

#[async_trait]
pub trait LoginAttemptRepositoryTrait: Send + Sync {
    async fn record_attempt(
        &self,
        user_id: Option<Uuid>,
        success: bool,
        device_id: Option<String>,
    ) -> AppResult<()>;

    async fn record_failed_attempt(
        &self,
        username: &str,
        ip: &str,
    ) -> AppResult<(i32, Option<chrono::NaiveDateTime>, Option<i32>)>;
}

// ── GradeComputationRepository trait ────────────────────────────────────────

#[async_trait]
pub trait GradeComputationRepositoryTrait: Send + Sync {
    async fn get_all_configs(&self, class_id: Uuid) -> AppResult<Vec<::entity::grade_record::Model>>;
    async fn setup_defaults(&self, class_id: Uuid, subject_group: &str) -> AppResult<Vec<::entity::grade_record::Model>>;
    async fn upsert_config(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
        ww_weight: f64,
        pt_weight: f64,
        qa_weight: f64,
    ) -> AppResult<::entity::grade_record::Model>;
    async fn get_items(&self, class_id: Uuid, grading_period_number: i32) -> AppResult<Vec<::entity::grade_items::Model>>;
    async fn create_item(
        &self,
        class_id: Uuid,
        title: String,
        component: String,
        grading_period_number: Option<i32>,
        total_points: f64,
        source_type: String,
        source_id: Option<String>,
        order_index: i32,
    ) -> AppResult<::entity::grade_items::Model>;
    async fn soft_delete_item(&self, id: Uuid) -> AppResult<()>;
    async fn get_scores_by_item(&self, grade_item_id: Uuid) -> AppResult<Vec<::entity::grade_scores::Model>>;
    async fn get_period_grade(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Option<::entity::period_grades::Model>>;
    async fn get_all_for_class(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Vec<::entity::period_grades::Model>>;
}

// ── TosRepository trait ──────────────────────────────────────────────────────

#[async_trait]
pub trait TosRepositoryTrait: Send + Sync {
    async fn find_by_class(&self, class_id: Uuid, teacher_id: Uuid) -> AppResult<Vec<::entity::table_of_specifications::Model>>;
    async fn find_by_id(&self, id: Uuid) -> AppResult<Option<::entity::table_of_specifications::Model>>;
    async fn create(&self, class_id: Uuid, teacher_id: Uuid, title: String) -> AppResult<::entity::table_of_specifications::Model>;
    async fn delete(&self, id: Uuid, teacher_id: Uuid) -> AppResult<()>;
}
