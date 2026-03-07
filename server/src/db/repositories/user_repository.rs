use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::{refresh_tokens, users};
use crate::utils::{AppError, AppResult};

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
        let user = users::ActiveModel {
            id: Set(client_id.unwrap_or_else(Uuid::new_v4)),
            username: Set(username),
            password_hash: Set(None),
            full_name: Set(full_name),
            role: Set(role),
            account_status: Set("pending_activation".to_string()),
            activated_at: Set(None),
            created_at: Set(Utc::now().naive_utc()),
            updated_at: Set(Utc::now().naive_utc()),
            deleted_at: Set(None),
        };

        user.insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create account: {}", e)))
    }

    pub async fn set_password(
        &self,
        user_id: Uuid,
        password_hash: String,
    ) -> AppResult<users::Model> {
        let user = users::ActiveModel {
            id: Set(user_id),
            password_hash: Set(Some(password_hash)),
            account_status: Set("activated".to_string()),
            activated_at: Set(Some(Utc::now().naive_utc())),
            updated_at: Set(Utc::now().naive_utc()),
            ..Default::default()
        };

        user.update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to set password: {}", e)))
    }

    pub async fn update_account_status(
        &self,
        user_id: Uuid,
        status: &str,
    ) -> AppResult<users::Model> {
        let user = users::ActiveModel {
            id: Set(user_id),
            account_status: Set(status.to_string()),
            updated_at: Set(Utc::now().naive_utc()),
            ..Default::default()
        };

        user.update(&self.db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!("Failed to update account status: {}", e))
            })
    }

    pub async fn clear_password(&self, user_id: Uuid) -> AppResult<users::Model> {
        let user = users::ActiveModel {
            id: Set(user_id),
            password_hash: Set(None),
            account_status: Set("pending_activation".to_string()),
            activated_at: Set(None),
            updated_at: Set(Utc::now().naive_utc()),
            ..Default::default()
        };

        user.update(&self.db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!("Failed to clear password: {}", e))
            })
    }

    pub async fn update_account(
        &self,
        user_id: Uuid,
        username: Option<String>,
        full_name: Option<String>,
        role: Option<String>,
    ) -> AppResult<users::Model> {
        let mut user: users::ActiveModel = users::Entity::find_by_id(user_id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?
            .into();

        if let Some(username) = username {
            user.username = Set(username);
        }
        if let Some(full_name) = full_name {
            user.full_name = Set(full_name);
        }
        if let Some(role) = role {
            user.role = Set(role);
        }
        user.updated_at = Set(Utc::now().naive_utc());

        user.update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update account: {}", e)))
    }

    pub async fn find_by_username(&self, username: &str) -> AppResult<Option<users::Model>> {
        users::Entity::find()
            .filter(users::Column::Username.eq(username))
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_by_id(&self, id: Uuid) -> AppResult<Option<users::Model>> {
        users::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_all_users(&self) -> AppResult<Vec<users::Model>> {
        users::Entity::find()
            .order_by_desc(users::Column::CreatedAt)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn search_students(&self, query: &str) -> AppResult<Vec<users::Model>> {
        let mut condition = Condition::all().add(users::Column::Role.eq("student"));

        if !query.is_empty() {
            condition = condition.add(
                Condition::any()
                    .add(users::Column::Username.contains(query))
                    .add(users::Column::FullName.contains(query)),
            );
        }

        users::Entity::find()
            .filter(condition)
            .order_by_asc(users::Column::FullName)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn create_refresh_token(
        &self,
        user_id: Uuid,
        token_hash: String,
        device_id: Option<String>,
        expires_at: chrono::NaiveDateTime,
    ) -> AppResult<refresh_tokens::Model> {
        let refresh_token = refresh_tokens::ActiveModel {
            id: Set(Uuid::new_v4()),
            user_id: Set(user_id),
            token_hash: Set(token_hash),
            device_id: Set(device_id),
            expires_at: Set(expires_at),
            created_at: Set(Utc::now().naive_utc()),
            revoked_at: Set(None),
        };

        refresh_token
            .insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create refresh token: {}", e)))
    }

    pub async fn find_refresh_token(&self, token_hash: &str) -> AppResult<Option<refresh_tokens::Model>> {
        refresh_tokens::Entity::find()
            .filter(refresh_tokens::Column::TokenHash.eq(token_hash))
            .filter(refresh_tokens::Column::RevokedAt.is_null())
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn revoke_refresh_token(&self, token_id: Uuid) -> AppResult<()> {
        let token = refresh_tokens::ActiveModel {
            id: Set(token_id),
            revoked_at: Set(Some(Utc::now().naive_utc())),
            ..Default::default()
        };

        token
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to revoke token: {}", e)))?;

        Ok(())
    }
}
