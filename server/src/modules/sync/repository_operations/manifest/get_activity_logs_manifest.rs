use sea_orm::*;
use uuid::Uuid;

use ::entity::activity_logs;
use crate::utils::{AppError, AppResult};
use super::ManifestEntry;

pub async fn get_activity_logs_manifest(
    db: &DatabaseConnection,
    user_id: Uuid,
    user_role: &str,
) -> AppResult<Vec<ManifestEntry>> {
    let records = if user_role == "admin" {
        activity_logs::Entity::find()
            .all(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
    } else {
        activity_logs::Entity::find()
            .filter(activity_logs::Column::UserId.eq(user_id))
            .all(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
    };

    Ok(records
        .into_iter()
        .map(|r| ManifestEntry {
            id: r.id,
            updated_at: r.created_at,
            deleted: false,
        })
        .collect())
}
