use std::sync::Arc;
use uuid::Uuid;
use crate::cache::{CacheInvalidator, RedisCache};
use crate::utils::AppResult;
use crate::modules::auth::schema::UserResponse;
use crate::modules::admin::schema::{AccountListResponse, CreateAccountRequest, UpdateAccountRequest, ResetAccountRequest, LockAccountRequest};
use crate::modules::admin::repository::AdminRepository;
use crate::modules::admin::service_operations::{
    create_account, update_account, reset_account, get_account, get_all_accounts,
    lock_account, delete_account, get_activity_logs, search_students,
};
use ::entity::activity_logs;

pub struct AdminService {
    pub repository: AdminRepository,
    cache: Option<Arc<RedisCache>>,
    invalidator: Option<CacheInvalidator>,
}

impl AdminService {
    pub fn new(db: sea_orm::DatabaseConnection) -> Self {
        Self {
            repository: AdminRepository::new(db),
            cache: None,
            invalidator: None,
        }
    }

    pub fn with_cache(mut self, cache: Arc<RedisCache>) -> Self {
        self.invalidator = Some(CacheInvalidator::new(cache.clone()));
        self.cache = Some(cache);
        self
    }

    pub async fn create_account(
        &self,
        request: CreateAccountRequest,
        created_by: Uuid,
        client_id: Option<Uuid>,
    ) -> AppResult<UserResponse> {
        create_account(
            &self.repository.user_repo,
            &self.repository.activity_log_repo,
            request,
            created_by,
            client_id,
        )
        .await
    }

    pub async fn update_account(
        &self,
        user_id: Uuid,
        request: UpdateAccountRequest,
        admin_id: Uuid,
    ) -> AppResult<UserResponse> {
        let result = update_account(
            &self.repository.user_repo,
            user_id,
            request,
            admin_id,
        ).await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_user_profile(user_id).await;
        }
        Ok(result)
    }

    pub async fn reset_account(
        &self,
        request: ResetAccountRequest,
        admin_id: Uuid,
    ) -> AppResult<UserResponse> {
        let user_id = request.user_id;
        let result = reset_account(
            &self.repository.user_repo,
            &self.repository.activity_log_repo,
            request,
            admin_id,
        ).await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_user_profile(user_id).await;
        }
        Ok(result)
    }

    pub async fn get_account(&self, user_id: Uuid) -> AppResult<UserResponse> {
        get_account(&self.repository.user_repo, user_id).await
    }

    pub async fn get_all_accounts(&self) -> AppResult<AccountListResponse> {
        get_all_accounts(&self.repository.user_repo).await
    }

    pub async fn lock_account(
        &self,
        request: LockAccountRequest,
        admin_id: Uuid,
    ) -> AppResult<UserResponse> {
        lock_account(
            &self.repository.user_repo,
            &self.repository.activity_log_repo,
            request,
            admin_id,
        )
        .await
    }

    pub async fn delete_account(&self, user_id: Uuid, admin_id: Uuid) -> AppResult<()> {
        delete_account(
            &self.repository.user_repo,
            &self.repository.activity_log_repo,
            user_id,
            admin_id,
        )
        .await
    }

    pub async fn get_activity_logs(&self, user_id: Uuid) -> AppResult<Vec<activity_logs::Model>> {
        get_activity_logs(&self.repository.activity_log_repo, user_id).await
    }

    pub async fn search_students(&self, query: &str) -> AppResult<Vec<UserResponse>> {
        search_students(&self.repository.user_repo, query).await
    }
}
