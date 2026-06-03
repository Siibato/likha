use sea_orm::DatabaseConnection;
use uuid::Uuid;

use ::entity::{refresh_tokens, users};
use crate::modules::auth::repository_operations::user as ops;
use crate::utils::AppResult;

pub struct UserRepository {
    db: DatabaseConnection,
}

impl UserRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn create_account(
        &self,
        username: String,
        full_name: String,
        role: String,
        client_id: Option<Uuid>,
    ) -> AppResult<users::Model> {
        ops::create_account(&self.db, username, full_name, role, client_id).await
    }

    pub async fn set_password(&self, user_id: Uuid, password_hash: String) -> AppResult<users::Model> {
        ops::set_password(&self.db, user_id, password_hash).await
    }

    pub async fn update_account_status(&self, user_id: Uuid, status: &str) -> AppResult<users::Model> {
        ops::update_account_status(&self.db, user_id, status).await
    }

    pub async fn clear_password(&self, user_id: Uuid) -> AppResult<users::Model> {
        ops::clear_password(&self.db, user_id).await
    }

    pub async fn update_account(
        &self,
        user_id: Uuid,
        full_name: Option<String>,
        role: Option<String>,
    ) -> AppResult<users::Model> {
        ops::update_account(&self.db, user_id, full_name, role).await
    }

    pub async fn find_by_username(&self, username: &str) -> AppResult<Option<users::Model>> {
        ops::find_by_username(&self.db, username).await
    }

    pub async fn find_by_id(&self, id: Uuid) -> AppResult<Option<users::Model>> {
        ops::find_by_id(&self.db, id).await
    }

    pub async fn find_all_users(&self) -> AppResult<Vec<users::Model>> {
        ops::find_all_users(&self.db).await
    }

    pub async fn search_students(&self, query: &str) -> AppResult<Vec<users::Model>> {
        ops::search_students(&self.db, query).await
    }

    pub async fn create_refresh_token(
        &self,
        user_id: Uuid,
        token_hash: String,
        device_id: Option<String>,
        expires_at: chrono::NaiveDateTime,
    ) -> AppResult<refresh_tokens::Model> {
        ops::create_refresh_token(&self.db, user_id, token_hash, device_id, expires_at).await
    }

    pub async fn find_refresh_token(&self, token_hash: &str) -> AppResult<Option<refresh_tokens::Model>> {
        ops::find_refresh_token(&self.db, token_hash).await
    }

    pub async fn revoke_refresh_token(&self, token_id: Uuid) -> AppResult<()> {
        ops::revoke_refresh_token(&self.db, token_id).await
    }

    pub async fn revoke_all_tokens_for_user(&self, user_id: Uuid) -> AppResult<u64> {
        ops::revoke_all_tokens_for_user(&self.db, user_id).await
    }

    pub async fn soft_delete(&self, user_id: Uuid) -> AppResult<()> {
        ops::soft_delete(&self.db, user_id).await
    }
}
