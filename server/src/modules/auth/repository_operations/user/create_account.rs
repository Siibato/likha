use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::users;
use crate::utils::{AppError, AppResult};

pub async fn create_account(
    db: &DatabaseConnection,
    username: String,
    first_name: String,
    last_name: String,
    role: String,
    client_id: Option<Uuid>,
) -> AppResult<users::Model> {
    let user = users::ActiveModel {
        id: Set(client_id.unwrap_or_else(Uuid::new_v4)),
        username: Set(username),
        password_hash: Set(None),
        first_name: Set(first_name),
        last_name: Set(last_name),
        role: Set(role),
        account_status: Set("pending_activation".to_string()),
        activated_at: Set(None),
        created_at: Set(Utc::now().naive_utc()),
        updated_at: Set(Utc::now().naive_utc()),
        deleted_at: Set(None),
    };

    user.insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to create account: {}", e)))
}
