use sea_orm::*;

use ::entity::users;
use crate::utils::{AppError, AppResult};

pub async fn find_all_users(db: &DatabaseConnection) -> AppResult<Vec<users::Model>> {
    users::Entity::find()
        .filter(users::Column::DeletedAt.is_null())
        .order_by_desc(users::Column::CreatedAt)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
