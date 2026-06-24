use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::users;

pub async fn update_account_status(
    db: &DatabaseConnection,
    user_id: Uuid,
    status: &str,
) -> AppResult<users::Model> {
    let user = users::ActiveModel {
        id: Set(user_id),
        account_status: Set(status.to_string()),
        updated_at: Set(Utc::now().naive_utc()),
        ..Default::default()
    };

    user.update(db).await.map_err(|e| {
        AppError::InternalServerError(format!("Failed to update account status: {}", e))
    })
}
