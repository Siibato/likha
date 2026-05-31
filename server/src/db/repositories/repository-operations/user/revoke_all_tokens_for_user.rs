use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};

pub async fn revoke_all_tokens_for_user(db: &DatabaseConnection, user_id: Uuid) -> AppResult<u64> {
    let now = Utc::now().naive_utc();
    let now_str = now.to_string();
    let user_id_str = user_id.to_string();

    let query = format!(
        "UPDATE refresh_tokens SET revoked_at = '{}' WHERE user_id = '{}' AND revoked_at IS NULL",
        now_str, user_id_str
    );

    let result = db
        .execute(sea_orm::Statement::from_string(
            sea_orm::DbBackend::Sqlite,
            query,
        ))
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to revoke tokens: {}", e)))?;

    Ok(result.rows_affected())
}
