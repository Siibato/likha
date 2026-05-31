use sea_orm::*;

use ::entity::classes;
use crate::utils::{AppError, AppResult};

pub async fn find_all(db: &DatabaseConnection) -> AppResult<Vec<classes::Model>> {
    classes::Entity::find()
        .filter(classes::Column::IsArchived.eq(false))
        .order_by_desc(classes::Column::CreatedAt)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
