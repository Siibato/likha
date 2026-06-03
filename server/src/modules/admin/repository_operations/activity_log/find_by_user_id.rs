use sea_orm::*;
use uuid::Uuid;

use ::entity::activity_logs;
use crate::utils::{AppError, AppResult};

pub async fn find_by_user_id(db: &DatabaseConnection, user_id: Uuid) -> AppResult<Vec<activity_logs::Model>> {
    activity_logs::Entity::find()
        .filter(activity_logs::Column::UserId.eq(user_id))
        .order_by_desc(activity_logs::Column::CreatedAt)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
