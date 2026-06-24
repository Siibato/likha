use crate::cache::{CacheInvalidator, RedisCache};
use crate::modules::admin::repository::AdminRepository;
use crate::modules::admin::schema::{
    AccountDetailResponse, AccountListResponse, CreateAccountRequest, LockAccountRequest,
    ResetAccountRequest, UpdateAccountDetailsRequest, UpdateAccountRequest,
};
use crate::modules::admin::service_operations::{
    bulk_import, create_account, delete_account, get_account, get_account_details,
    get_activity_logs, get_all_accounts, lock_account, reset_account, search_students,
    update_account, upsert_account_details,
};
use crate::modules::auth::schema::UserResponse;
use crate::utils::AppResult;
use ::entity::activity_logs;
use std::sync::Arc;
use uuid::Uuid;

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
            &self.repository.db,
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
        let result = update_account(&self.repository.user_repo, user_id, request, admin_id).await?;
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
        )
        .await?;
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

    pub async fn get_account_details(&self, user_id: Uuid) -> AppResult<AccountDetailResponse> {
        get_account_details(&self.repository.db, &self.repository.user_repo, user_id).await
    }

    pub async fn upsert_account_details(
        &self,
        user_id: Uuid,
        request: UpdateAccountDetailsRequest,
    ) -> AppResult<AccountDetailResponse> {
        let user = self
            .repository
            .user_repo
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| crate::utils::error::AppError::NotFound("User not found".to_string()))?;

        upsert_account_details(
            &self.repository.db,
            user_id,
            &user.role,
            request.learner_details,
            request.teacher_details,
        )
        .await?;

        self.get_account_details(user_id).await
    }

    pub async fn preview_student_import(
        &self,
        csv_bytes: &[u8],
    ) -> AppResult<crate::modules::admin::import_schema::PreviewResponse> {
        bulk_import::preview_students(&self.repository.db, &self.repository.user_repo, csv_bytes)
            .await
    }

    pub async fn import_students(
        &self,
        rows: Vec<serde_json::Value>,
    ) -> AppResult<crate::modules::admin::import_schema::ImportResultResponse> {
        bulk_import::import_students(&self.repository.db, &self.repository.user_repo, &rows).await
    }
}
